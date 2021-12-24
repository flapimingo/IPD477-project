
classdef proc_power_transform
% Do a simple squaring of the dataset, followed by optional log() transform
%

	properties
		usedParams
	end
	methods

	function [obj, feats] = train(obj, trainData, varargin )

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'logFeats',               false,           @islogical);
		addParameter(p, 'logEps',                 0.0001,          @isnumeric);

		p.parse(varargin{:});
		params = p.Results;

		%%%%%%%%%%%%

		obj.usedParams = params;

		% do not extract any features, let caller do on demand
		feats = [];

	end


	function feats = process(obj, dataset)
		assert(~isempty(obj.usedParams));

		feats = (dataset.X).^2;

		if(obj.usedParams.logFeats)
			feats = log(feats+obj.usedParams.logEps);
		end

	end

	end

end
