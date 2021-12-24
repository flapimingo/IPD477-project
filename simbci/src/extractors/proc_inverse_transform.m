
classdef proc_inverse_transform
% Feature extraction based on inverse transforms and a provided forward model.
%
% If requested, can return a feature subset based on an (optimistic) ROI guess.
%

	properties
		forwardModel
		ROIIndexes
		usedParams
	end
	methods

	function [obj, feats] = train(obj, trainData, varargin )
	% Train the feature extractor

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'forward',                @core_head,       @isfunlist);	
		addParameter(p, 'inverse',                @wmn_inverse,     @isfunlist);
		addParameter(p, 'ROISelection',           {},               @isfunlist);		
		addParameter(p, 'signalPower',            false,            @islogical);
		addParameter(p, 'visualize',              false,            @islogical);
		
		p.parse(varargin{:});
		obj.usedParams = p.Results;

		%%%%%%%%%%%

		[headFun,headParams] = split_funlist(obj.usedParams.forward);
		
		obj.forwardModel = headFun(headParams{:});

		%%%%%%%%%%%%

		if(~isempty(obj.usedParams.ROISelection))
			[roiFun,roiParams] = split_funlist(obj.usedParams.ROISelection);
			guessedROI = roiFun(obj.forwardModel, roiParams{:});

			obj.ROIIndexes = unique(cat(1,guessedROI{:})); % cat() flattens the array
		end

		% Compute only on demand
		feats = [];

		if(obj.usedParams.visualize && ~isempty(obj.usedParams.ROISelection))
			figure();
			colors={'ro','bo','ko','mo','yo'};
			for i=1:length(guessedROI)
				obj.forwardModel.visualize(guessedROI{i}, [], [], colors{rem(i-1,5)+1}, 5);
			end
			title('Guessed ROIs for inverse');
		end
	end

	function feats = process(obj, dataset)
	% Extract features
		assert(~isempty(obj.forwardModel));

		% @FIXME refactor this out as a pipeline stage
		XFiltered = filter_bandpass(dataset.X, dataset.samplingFreq, 3, 30);
				
		[invFun,invParams] = split_funlist(obj.usedParams.inverse);
			
		feats = invFun(obj.forwardModel.A, XFiltered', obj.forwardModel.constrainedOrientation, invParams{:});

		if(~isempty(obj.usedParams.ROISelection))
			feats = feats(obj.ROIIndexes,:);
		end
		
		% @FIXME refactor out as a pipeline stage
		if(obj.usedParams.signalPower)
			feats = current_dipoles_to_dipole_power(feats, ~physicalModel.constrainedOrientation);
		end
	
		feats = feats';
	end

	end

end

