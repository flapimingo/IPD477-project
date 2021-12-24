
classdef proc_lda
	% Linear Discriminant Analysis classifier

	properties
		classModels
		numClasses
		usedParams
	end
	methods

	function [obj, pred] = train(obj, trainData, varargin )
	% Estimate a multiclass LDA classifier

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'call',                   @proc_lda,    @isfun);
		addParameter(p, 'tikhonov',               0.0,      @isnumeric);
		addParameter(p, 'shrink',                 0.0,	    @isnumeric);
		addParameter(p, 'quadratic',              false,    @islogical);
		addParameter(p, 'visualize',              false,    @islogical);

		p.parse(varargin{:});
		params = p.Results;

		%%%

		% Check if the feature extractor returned vector per trial.
		% FIXME should be outside this function, e.g. each step converts (data,label) pair
		if(size(trainData.X,1)==size(trainData.trialLabels,1))
			labels = trainData.trialLabels;
		else
			labels = trainData.sampleLabels;
		end

		% Ignore class 0
		usedSamples = (labels>0);
		nTotalSamples = sum(usedSamples);

		if(~params.quadratic)
			% In the linear LDA, all models share the COV
			[COV, invCOV, COV_E, COV_D] = robust_invcov(trainData.X(usedSamples,:), params.tikhonov, params.shrink);
		end

		obj.classModels=cell(trainData.numClasses,1);
		for i=1:trainData.numClasses

			inClassSamples = (labels==i);

			if(params.quadratic)
				[COV, invCOV, COV_E, COV_D] = robust_invcov(trainData.X(inClassSamples,:), params.tikhonov, params.shrink);
			end

			classModel=[];
			classModel.m = mean(trainData.X(inClassSamples,:),1)'; % class i
			classModel.invCOV = invCOV;
			classModel.COV_E = COV_E;
			classModel.COV_D = COV_D;

			if(~params.quadratic)
				classModel.f = classModel.invCOV*classModel.m;
				classModel.bias = -0.5 * classModel.m' * classModel.invCOV * classModel.m +...
									  log(sum(inClassSamples)/nTotalSamples);
			else
				classModel.bias = -0.5 * log(max(diag(COV_D)))  +...
									  log(sum(inClassSamples)/nTotalSamples);
			end

			obj.classModels{i} = classModel;
		end

		obj.numClasses = trainData.numClasses;
		obj.usedParams = params;

		pred = [];
	end

	function raw = process(obj,dataset)
	% Classify new data with a pre-estimated LDA model
		assert(~isempty(obj.classModels));

		% Raw classification
		raw = zeros(size(dataset.X,1), obj.numClasses);

		for i=1:obj.numClasses
			if(~obj.usedParams.quadratic)
				raw(:, i) = (obj.classModels{i}.f'*dataset.X'+obj.classModels{i}.bias)';
			else
				centered = dataset.X-repmat(obj.classModels{i}.m',[size(dataset.X,1) 1]);
				raw(:, i) = -sum( (centered * obj.classModels{i}.invCOV) .* centered, 2) + obj.classModels{i}.bias;
			end
		end

		% map to labels
		% [~,prediction] = max(raw,[],2);
	end

	end

end

