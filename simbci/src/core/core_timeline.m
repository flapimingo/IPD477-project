classdef core_timeline
	% Various functions related to generating BCI timelines and event manipulation

	properties
		event           % same as 'events' field in datasets
		numSamples      % length of the timeline, in samples

		usedParams
	end

	methods

	function obj = core_timeline( varargin )
	% Default constructor
	%
	% A timeline consists of a sequence of events each having a name and a time of occurrence in ms.
	% As its input, this class takes a list of event generators (in folder 'events/')
	%
	% Internally the event times are stored as sample indexes, hence sampling frequency is needed
	%
	% The duration of the timeline/dataset depends on the number of trials and
	% trial lengths etc
	%	
	
		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		defaultList = {{'when', @when_trials, 'whenParams', {'events',{'class1','class2'}, ...
		    'numTrials',10, 'trialOrder', 'random', 'includeRest', true}}};
		
		addParameter(p,'samplingFreq',       200,          @isint);
		addParameter(p,'eventList',          defaultList,  @iscell);
		
		p.parse(varargin{:});

		%%%%%%
		
		obj.usedParams = p.Results;
		
		obj.numSamples = 0;
		
	end
	
	function obj = generate(obj)
	% CLASS_TIMELINE Generate an experiment timeline 
	%
	% This function can be called repeatedly to get the random events (if any) in different positions
	% using the same design
	
		partList = obj.usedParams.eventList;
		
		obj.numSamples = 0;
		obj.event = [];
		
		% Generate experiment timeline and make an initial empty dataset from it with labels
		% allParams = {};
		for i=1:length(partList)
			thisPart = partList{i};
			
			% parse arguments
			p = inputParser;
			p.KeepUnmatched = false;
			p.CaseSensitive = true;
			p.PartialMatching = false;

			addParameter(p,'when',                @when_always,   @isfunlist);
			addParameter(p,'whenParams',          {},             @iscell);
			addParameter(p,'visualize',           false,          @isbool);
			
			p.parse(thisPart{:});

			params = p.Results;
	
			%%%%

			[whenFun,whenParams] = split_funlist(params.when);	
			
			[addedEvents,addedParams] = whenFun('numSamples', obj.numSamples, ...
				'samplingFreq', obj.usedParams.samplingFreq, whenParams{:} );
			
			assert(size(addedEvents,2)>=size(addedEvents,1));

			if(params.visualize)
				tmp = obj.event;
				obj.event = addedEvents;
				obj.visualize();
				obj.event = tmp;
			end
			
			obj = obj.merge_events(addedEvents);
		
			% Recompute the dataset length; @todo could compute in merge?
			obj = update_num_samples(obj);
			
			%allParams = {allParams;addedParams};			
		end
	end

	function obj = construct_from_events( obj, events )
		% Construct timeline from an events array
		obj.event = events;
	end

	function length = get_session_length(obj)
		length = obj.numSamples;
		
		% the latest index of event.start+duration over all events.
		% @fixme this is not very efficient...
		%length = 0;
		%for i=1:length(obj.event)
		%	eventEnd = obj.event(i).latency + obj.event(i).duration;
		%	length = max(length,eventEnd);
		%end
	end

	function mask = get_mask(obj, eventType)
	% Returns 1 for each sample where eventType is 'active' (i.e. sample time in [timems,timems+duration]
	%
	% Special reserved eventTypes 'always' and 'never' have their intuitive meanings.
	% n.b. for understanding the generated datasets it might be a good idea to have
	% events in the timeline that are reacted to, even if these events are 'for the whole
	% duration' type of events.
	%
		if(strcmp(eventType,'always'))
			mask = ones(obj.get_session_length(),1);
		elseif(strcmp(eventType,'never'))
			mask = zeros(obj.get_session_length(),1);
		else
			mask = zeros(obj.get_session_length(),1);
			for i=1:length(obj.event)
				if(strcmp(obj.event(i).type, eventType))
					startIdx = obj.event(i).latency;
					stopIdx = startIdx + obj.event(i).duration;
					mask(startIdx:stopIdx) = 1;
				end
			end
		end
		assert(size(mask,1) == obj.get_session_length());
		
		% figure(); plot(mask); 
		% title(sprintf('Mask for event type %s',eventType));
		% drawnow;
		% mask = logical(mask);
	end
	
	function events = get_events(obj)
	% Return the events of the timeline
		events = obj.event;
	end

	function dataset = get_empty_dataset(obj)
	% Return the timeline as an empty dataset.
		events = obj.event;

		assert(~isempty(events),'Construct timeline first');

		dataset=[];
		dataset.id = 'anon';
		dataset.events = events;
		dataset.numSamples = obj.numSamples;
		dataset.samplingFreq = obj.usedParams.samplingFreq;
		dataset.timelineParams = obj.usedParams;

	end

	function paramList = get_params(obj)
	% Returns the used parameters.
	%
	% defaultParams = core_timeline().get_params();
	%
		paramList = struct_to_list(obj.usedParams);
	end

	function obj = merge_events( obj, moreEvents )
	% Merges the given array of events to the timeline

		events1 = obj.event;
		events2 = moreEvents;

		assert(size(events1,2)>=size(events1,1));
		assert(size(events2,2)>=size(events2,1));

		if(isempty(events1))
			obj.event = events2;
			return;
		end
		if(isempty(events2))
			obj.event = events1;
			return;
		end

		totalLen = size(events1,2) + size(events2,2);

		newEvents = repmat(events1(1),[1 totalLen]);
				
		cnt1 = 1; cnt2 = 1; newCnt = 1;
		while(cnt1 <= size(events1,2) || cnt2 <= size(events2,2))
			if(cnt1 > size(events1,2))
				% we've exhausted events1, pad from events2
				newEvents(newCnt) = events2(cnt2);
				cnt2 = cnt2 + 1;
			elseif( cnt2 > size(events2,2))
				% we've exhausted events2, pad from events1
				newEvents(newCnt) = events1(cnt1);
				cnt1 = cnt1 + 1;
			elseif(events1(cnt1).latency == events2(cnt2).latency)
				% two events exactly at the same time
				
				if(isequal(events1(cnt1).type,events2(cnt2).type))
					% same event at same time, take only one by skipping event from second set
					cnt2=cnt2+1;
				end
				
				newEvents(newCnt) = events1(cnt1);
				cnt1 = cnt1 + 1;
			elseif(events1(cnt1).latency < events2(cnt2).latency)
				% event1 is before event2
				newEvents(newCnt) = events1(cnt1);
				cnt1 = cnt1 + 1;
			else
				% event2 is before event1
				newEvents(newCnt) = events2(cnt2);
				cnt2 = cnt2 + 1;
			end
			newCnt = newCnt + 1;
		end
		newCnt = newCnt - 1;
		
		% truncate as we may have got rid of some duplicates
		assert(newCnt == cnt1+cnt2-2);
		
		newEvents = newEvents(1:newCnt);

		obj.event = newEvents;
	end

	function visualize(obj)
	% Displays occurrences of class events in a constructed timeline
		tmp = obj.get_empty_dataset();

		timeInSecs = (0:obj.numSamples-1)/obj.usedParams.samplingFreq;
		
		%plot(timeInSecs,zeros(1,obj.numSamples));

		% find unique events
		allEvents = cell(length(tmp.events),1);
		%allTimes = zeros(length(tmp.events),1);
		%allDurations = zeros(length(tmp.events),1);
		for i=1:length(tmp.events)
			allEvents{i} = tmp.events(i).type;
			%allTimes(i) = tmp.events(i).latency;
			%allDurations(i) = tmp.events(i).duration;
		end
		u = unique(allEvents);
		
		if(1)
			% plot each event except the class events with a different symbol
			symbols = {'+:','x:','o:','*:','.:','s:','d:','v:','p:'};
			hold on;
			for i=1:length(u)
			%	matches = ismember(allEvents, u(i));
			%	plot(allTimes(matches)/1000, 0.5.*ones(sum(matches),1), symbols{rem(i-1,5)+1});
			
				mask = obj.get_mask(u(i));
				plot(timeInSecs,mask.*(i-length(u)/2),symbols{rem(i-1,5)+1});
			end
		end

		xlabel('Time(s)');
		% ylabel('Trial class');
		title(sprintf('Timeline'));
		
		legend(u);
		hold off;
	end

	end

	methods(Access = private)
	
		function obj = update_num_samples(obj)
		% re-estimate number of samples
			obj.numSamples = 0;
			for i=1:length(obj.event)
				obj.numSamples = max(obj.numSamples,obj.event(i).latency + obj.event(i).duration);
			end		
		end
	end
			
end

