
classdef proc_csp_bandpower < proc_csp
% CSP/BandPower feature extractor
	properties
		% inherited from base class
	end
	methods

	function [obj, feats] = train(obj, trainData, varargin )
	% Train a CSP-bandpower model

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'freqLow',                8,               @isnumeric);
		addParameter(p, 'freqHigh',               30,              @isnumeric);
		addParameter(p, 'logFeats',               false,           @islogical);
		addParameter(p, 'logEps',                 0.0001,          @isnumeric);
		addParameter(p, 'tikhonov',               0,               @isnumeric);
		addParameter(p, 'shrink',                 0,               @isnumeric);
		addParameter(p, 'dim',                    2,               @isint);
		addParameter(p, 'visualize',              false,           @islogical);

		p.parse(varargin{:});
		params = p.Results;

		%%%%%%%%%%%%

		% Filter first, it will make the CSP optimization focus on the selected band.
		trainData.X = filter_bandpass(trainData.X, trainData.samplingFreq, params.freqLow, params.freqHigh);

		obj.modelCSP = obj.csp_train_impl(trainData, params );
		obj.usedParams = params;

		% do not extract any features, let caller do on demand
		feats = [];

	end


	function feats = process(obj, dataset)
	% Extract CSP/Bandpower features
		assert(~isempty(obj.modelCSP));

		feats = obj.csp_extract_impl(dataset, obj.modelCSP);

		% filtering before or after linear transform should be equivalent, so
		% we do it after as the dim has been reduced
		feats = filter_bandpass(feats, dataset.samplingFreq,  obj.usedParams.freqLow,  obj.usedParams.freqHigh);

		feats = feats.^2;

		if(obj.usedParams.logFeats)
			feats = log(feats+obj.usedParams.logEps);
		end

		if(obj.usedParams.visualize)
			figure();
			tit = sprintf('%s - CSP', dataset.id);
			imagesc(normalize(feats)); title(tit);
			drawnow;
		end

	end

	end

end
