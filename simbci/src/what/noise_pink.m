
function [noise,details, params] = noise_pink( sizeof, varargin )
% pink 1/f noise

	p = inputParser;
	p.KeepUnmatched = true;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'mask',                   [],    @isnumeric); 
	addParameter(p, 'exponent',               1.7,   @isnumeric);

	p.parse(varargin{:});
	params = p.Results;

	%%%%%%

	% n.b. seed not needed, uses globally the default rng
	noisegen = dsp.ColoredNoise('InverseFrequencyPower',params.exponent,'NumChannels',sizeof(2),'SamplesPerFrame',sizeof(1));
	noise = noisegen.step();

	if(~isempty(params.mask))
		noise = noise .* repmat(params.mask, [1 sizeof(2)]);
	end
	
	details = [];

end

