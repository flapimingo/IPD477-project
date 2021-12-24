
function [noise,details,params] = noise_logunif( sizeof, varargin )
% log-uniform noise with an binomial sign

	p = inputParser;
	p.KeepUnmatched = true;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'mask',                   [],    @isnumeric); 

	p.parse(varargin{:});
	params = p.Results;

	%%%% 
	
	noise = sign(rand(sizeof)-0.5).*log(rand(sizeof));

	if(~isempty(params.mask))
		noise = noise .* repmat(params.mask, [1 sizeof(2)]);
	end
	
	details = [];
	params = [];

end

