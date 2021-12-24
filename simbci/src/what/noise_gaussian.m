
function [noise,details,params] = noise_gaussian( sizeof, varargin )
% Symmetric Gaussian noise with specifiable mean and variance
%
% Note that SNR spec later may change the effective var
%

	p = inputParser;
	p.KeepUnmatched = true;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'mask',                   [],    @isnumeric); 
	addParameter(p, 'mean',                   [],    @isnumeric);  % add a vector +mean to all nonmasked samples, default=none (+0)	
	addParameter(p, 'var',                    1,     @isnumeric);
	
	p.parse(varargin{:});
	params = p.Results;
	
	%%%%%%
	
	noise = randn(sizeof) .* sqrt(params.var);

	if(~isempty(params.mean))
		if(size(params.mean,1)==1)
			noise = noise + repmat(params.mean, sizeof);
		else
			noise = noise + repmat(params.mean, [sizeof(1) 1]);
		end
	end
	if(~isempty(params.mask))
		noise = noise .* repmat(params.mask, [1 sizeof(2)]);
	end	

	details = [];

end

