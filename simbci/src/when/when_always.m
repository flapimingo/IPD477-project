
function [events,params] = when_always( varargin )
% Creates an event at the beginning that has a duration until the end of the dataset

	% parse arguments
	p = inputParser;
	p.KeepUnmatched = false;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p,'numSamples',          0,         @isnumeric);	
	addParameter(p,'samplingFreq',        0,         @isnumeric);		% not used
	addParameter(p,'events',              {'noise'}, @iscell);
	
	p.parse(varargin{:});
	params = p.Results;

	%%%%%%%%%

	assert(length(params.events)==1);
	assert(params.numSamples>0, 'Calling when_always() needs positive numSamples from a previous generator\n');
	
	events = [];
	events.type = params.events{1};
	events.latency = 1;
	events.duration = params.numSamples;
		
end

