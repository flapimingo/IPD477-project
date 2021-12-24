
function [S,details,params] = gen_binary( sizeof, varargin )
% returns data where a source is 1 when its corresponding class is active.

	% parse arguments
	p = inputParser;
	p.KeepUnmatched = false;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'dataset',                [],    @isstruct);  % not used
	addParameter(p, 'physicalModel',          core_head);	      % not used

	p.parse(varargin{:});
	params = p.Results;

	%%%%%%%%%%

	numSamples = sizeof(1);
	numSources = sizeof(2);
	
	assert(length(mask)==numSamples);
	
	S = repmat((mask==1),[1 numSources]);

	details = [];

end

