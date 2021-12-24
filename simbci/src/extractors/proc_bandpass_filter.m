
classdef proc_bandpass_filter
% Simple band pass filter feature processor

	properties
		usedParams
	end
	methods

	function [obj, feats] = train(obj, ~, varargin )

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'freqLow',                8,               @isnumeric);
		addParameter(p, 'freqHigh',               30,              @isnumeric);
		addParameter(p, 'order',                  2,               @isint);

		p.parse(varargin{:});
		params = p.Results;

		%%%%%%%%%%%%

		obj.usedParams = params;

		% do not extract any features, let caller do on demand
		feats = [];

	end


	function feats = process(obj, dataset)
		assert(~isempty(obj.usedParams.freqLow));

		feats = filter_bandpass(dataset.X, dataset.samplingFreq,  obj.usedParams.freqLow,  obj.usedParams.freqHigh, obj.usedParams.order);

	end

	end

end
