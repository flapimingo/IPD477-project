
function [events,params] = when_empty( varargin )
% Creates an empty timeline of desired length.
%
%
	% parse arguments
	p = inputParser;
	p.KeepUnmatched = false;
	p.CaseSensitive = true;
	p.PartialMatching = false;
	
	addParameter(p,'numSamples',          0,        @isnumeric);
	addParameter(p,'lengthSecs',          10*60,    @isnumeric);
	addParameter(p,'samplingFreq',        200,      @isnumeric);	
	
	p.parse(varargin{:});
	params = p.Results;

	%%%%%%%%%

	assert(params.numSamples == 0 || params.lengthSecs == 0, 'Provide either numSamples>0 or lengthSecs>0, not both');
	if(params.numSamples==0)
		params.numSamples = params.lengthSecs * params.samplingFreq;
	end
	
	events=[];
	
	events(1).type = 'start';
	events(1).latency = 1;
	events(1).duration = 0;
	
	events(2).type = 'end';
	events(2).latency = params.numSamples + 1;
	events(2).duration = 0;
		
end

