

classdef proc_md_classifier
	% Mahalanobis Distance based Classifier, used e.g. in Edelman & He 2016
	%
	% Assumes that features are in class order, i.e. 1:featsPerClass columns
	% of trainData.X are intended to model class 1 and so on.
	%
	% Alternatively, all classes can use the same features by setting featsPerClass=0.
	% 
	% @author Jussi T. Lindgren / Inria based on the original code of CERL/IMT
	% 
	
	properties
		model

		usedParams
	end
	methods
		
	function [obj, pred] = train( obj, trainData, varargin )
	% Train the classifier

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'featsPerClass',          5,      @isint); % use 0 to make all classes share features
		addParameter(p, 'visualize',              false,  @islogical);
		
		p.parse(varargin{:});
		obj.usedParams = p.Results;
		
		%%%%%%%%%%%%%%%
		
		obj.model=[];

		obj.model.numClasses = trainData.numClasses;
		obj.model.averages = cell(obj.model.numClasses);
		obj.model.invCovariances = cell(obj.model.numClasses);

		featsPerClass = obj.usedParams.featsPerClass;
		
		assert(featsPerClass==0 || rem(size(trainData.X,2),featsPerClass)==0);
		
		for i=1:obj.model.numClasses
			inclassIdxs = (trainData.sampleLabels==i);
			if(featsPerClass>0)
				inclassFeats = ((i-1) * featsPerClass + 1):(i * featsPerClass);
			else
				inclassFeats = 1:size(trainData.X,2); % all classes share same features
			end
			
			classX = trainData.X(inclassIdxs,inclassFeats);
			
			% Adhoc regularization by pinv: If co is invertible, result is equal to inv.
			% If not, we get an approximation.
			obj.model.averages{i} = mean(classX);
			obj.model.invCovariances{i} = pinv(cov(classX));
		end

		pred = [];
		
	end

	function raw = process(obj, dataset)
	% Classifies new examples

		raw = zeros(size(dataset.X, 1), obj.model.numClasses);

		featsPerClass = obj.usedParams.featsPerClass;

		% @todo inefficient; try to use matrix math instead of looping over all samples			
		for j=1:obj.model.numClasses
			if(featsPerClass>0)	
				inclassFeats = ((j-1) * featsPerClass + 1):(j * featsPerClass);
			else
				inclassFeats = 1:size(trainData.X,2); % all classes share the same features
			end
			
			taskX = dataset.X(:, inclassFeats);
			for i=1:size(taskX, 1)
				raw(i, j) = compute_point_mahalanobis_distance(taskX(i, :), obj.model.averages{j},...
																			obj.model.invCovariances{j});
			end
		end
	
		% The zero distance implies the largest class affinity, so we flip the distances and normalize to get probs
		raw(raw<0) = 0; % shouldn't have these if distance above behaves
		raw = exp(-raw);
		raw = raw./repmat(sum(raw,2),[1 size(raw,2)]);
		
		if(obj.usedParams.visualize)
			tit=sprintf('MD Classifier predictions (%s)', dataset.id);	
			figure(); imagesc(raw); ylabel('Time'); xlabel('Class'); title(tit);
		end
			
	end



	end %  methods
	
end
	
