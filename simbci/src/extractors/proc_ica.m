

classdef proc_ica
	% Just runs Independent Components Analysis and returns the components (ICA S matrix)
	% 
	
	properties
		model
		usedParams
	end
	methods
		
	function [obj,feats] = train(obj, trainData, varargin)
	% Trains an ICA model
	
		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'pcaDims',                8,               @isint);
		addParameter(p, 'verbose',                'off',           @ischar);
		addParameter(p, 'visualize',              false,           @islogical);
		
		p.parse(varargin{:});
		params = p.Results;

		% Run ICA first
		[weights,sphere,compvars,bias,signs,lrates,activations] = ...
			runica(trainData.X','pca',params.pcaDims, 'verbose', params.verbose, ...
			'reset_randomseed', 'off');	
		if(~isreal(weights))
			fprintf(1,'Warning: ICA returned imaginary weighting\n');
			weights = real(weights); sphere=real(sphere);
		end
		obj.model.icaW = weights * sphere;		% Multiplication by 'sphere' is needed if PCA is not used (with pca, no effect)
		obj.model.icaA = pinv(obj.model.icaW);

		% on-demand only
		feats = [];
	end

	function feats = process(obj, dataset)
		
		feats = (obj.model.icaW * dataset.X')';

	end

	end % methods
end
	