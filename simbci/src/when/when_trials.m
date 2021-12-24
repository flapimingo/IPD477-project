
function [events,params] = when_trials( varargin )
% Creates an event sequence of trials.
%
% For example, for two-class motor imagery, the call could be
%
% events = when_trials('events',{'LEFT','RIGHT'});
%
% and the resulting event sequence would be like
%
% START BURN-IN LEFT REST RIGHT REST ... REST END
%
% The lengths of trials, rest, etc can be configured.
%
	% parse arguments
	p = inputParser;
	p.KeepUnmatched = false;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p,'numSamples',          0,        @isnumeric);	
	addParameter(p,'events',              {'class1','class2'}, @iscell); % trials are of these types
	addParameter(p,'samplingFreq',        200,      @isnumeric);	
	addParameter(p,'numTrials',           12,       @isint);
	addParameter(p,'burninMs',            10000,    @isnumeric);	% duration of burn-in before first trial, 0 to disable
	addParameter(p,'trialLengthMs',       4000,     @isnumeric);	% duration for trials with a class
	addParameter(p,'restLengthMs',        2000,     @isnumeric);
	addParameter(p,'includeRest',         true,     @islogical);
	addParameter(p,'classWeights',        [],       @isnumeric);    % random sample the trial labels according to weights
	addParameter(p,'trialOrder',          'random', @ischar);
	addParameter(p,'visualize',  		  false,    @islogical);
	
	p.parse(varargin{:});
	params = p.Results;

	%%%%%%%%%

	assert(params.numSamples == 0, 'when_trials() will compute session length by itself');

	numClasses = length(params.events);
	
	if(isempty(params.classWeights))
		% equal weighted, always fixed number of trials per class
		assert(mod(params.numTrials, numClasses) == 0,...
			'Number of trials should be a multiple of number of classes.');
		trialsPerClass = params.numTrials / numClasses;
		trialLabels = repmat((1:numClasses)', [trialsPerClass 1]);
	else
		% Sample trial labels according to the given weight
		assert(length(params.classWeights)==numClasses);
		assert(all(params.classWeights>0));

		% @FIXME fix pipelines when some class is not present
		trialLabels = sample_items(1:numClasses, params.classWeights, params.numTrials);
	end

	if(isequal(params.trialOrder,'random'))
		% Permute the trials to random order
		rp = randperm(length(trialLabels));
		trialLabels = trialLabels(rp);
	elseif(isequal(params.trialOrder,'increasing'))
		% increasing order
		trialLabels = sort(trialLabels,'ascend');
	elseif(isequal(params.trialOrder,'roundrobin'))
		assert(isempty(params.classWeights), 'Can not use roundrobin with sampling');
		% round robin, nop
	else
		assert(false,'Unknown trial order requested');
	end

	cnt = 1;
	currentTime = 1;

	events=[];
	events(cnt).type = 'start';
	events(cnt).latency = currentTime;
	events(cnt).duration = 1*params.samplingFreq;  % 1 second
	
	currentTime = currentTime + events(cnt).duration;

	cnt=cnt+1;
	if(params.burninMs>0)
		events(cnt).type = 'burn-in';
		events(cnt).latency = currentTime;
		events(cnt).duration = round( (params.burninMs / 1000) * params.samplingFreq );
		currentTime = currentTime + events(cnt).duration;
		cnt = cnt + 1;		
	end

	for i=1:length(trialLabels)
		events(cnt).type = params.events{trialLabels(i)};
		events(cnt).latency = currentTime;
		events(cnt).duration = round( (params.trialLengthMs / 1000) * params.samplingFreq );
		currentTime = currentTime  + events(cnt).duration;
		cnt = cnt + 1; 
		if(params.includeRest)
			events(cnt).type = 'rest';
			events(cnt).latency = currentTime;
			events(cnt).duration = round( (params.restLengthMs / 1000) * params.samplingFreq );
			currentTime = currentTime + events(cnt).duration;
			cnt = cnt + 1; 
		end
	end

	events(cnt).type = 'end';
	events(cnt).latency = currentTime;
	events(cnt).duration = 0;
		
	for i=2:length(events)
		assert(events(i).latency>events(i-1).latency);
	end
	
end

