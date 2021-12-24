
function [events,params] = when_random( varargin )
% Creates random events from a Poisson process.
% 
% The events can have a fixed or random duration.
%

	% parse arguments
	p = inputParser;
	p.KeepUnmatched = false;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	% @FIXME add ms postfix to all duration to make clear the units
	addParameter(p,'numSamples',          0,         @isnumeric);	
	addParameter(p,'events',              {'blip'},  @iscell);
	addParameter(p,'eventFreq',           0.5,       @isnumeric);
	addParameter(p,'durationMs',          0,         @isnumeric);
	addParameter(p,'randomMaxDurationMs', 0,         @isnumeric);
	addParameter(p,'samplingFreq',        0,         @isnumeric);		
	
	p.parse(varargin{:});
	params = p.Results;

	%%%%%%%%%

	assert(length(params.events)==1);
	assert(params.numSamples>0, 'Calling when_random() needs positive numSamples from a previous generator');
	
	events = [];

	% draw occurrence times from a Poisson process	
	timeNow = 0; endTime = (params.numSamples/params.samplingFreq); % seconds
	while(timeNow<endTime)
		nextTime = timeNow + (-log(1-rand(1))/params.eventFreq);
		
		if(nextTime<endTime)
			event=[];
			event.type = params.events{1};
			event.latency = round(nextTime * params.samplingFreq);
			if(params.randomMaxDurationMs>0)
				event.duration = round(rand(1)*params.randomMaxDurationMs/1000 * params.samplingFreq);
			else
				event.duration = round( (params.durationMs/1000) * params.samplingFreq );
			end
			events = [events, event];
		end
		timeNow = nextTime;
	end

end

