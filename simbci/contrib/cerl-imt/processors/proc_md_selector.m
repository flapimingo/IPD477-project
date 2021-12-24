
classdef proc_md_selector
	% Mahalanobis Distance based 'greedy' feature selector, used e.g. in Edelman & He 2016
	%
	% Returns 'featsPerClass' features per each class, the first class features first
	% in 1:featsPerClass columns, and so on.
	% 
	% @author Jussi T. Lindgren / Inria based on the original code of CERL/IMT
	%
	
	properties
		allSelectedFeatures

		usedParams
	end
	methods
		
	function [obj, feats] = train( obj, trainData, varargin )
		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'featsPerClass',          5,      @isint); % How many features to pick per class
		addParameter(p, 'visualize',              false,  @islogical);
		
		p.parse(varargin{:});
		obj.usedParams = p.Results;
		
		%%%%
		
		numClasses = trainData.numClasses;
		
		obj.allSelectedFeatures = [];

		if(obj.usedParams.visualize)
			figure();
		end
		
		for c=1:numClasses
			selectedFeatures = [];
			unselectedFeatures = 1:size(trainData.X,2);
	
			% for each class, collect certain number of features
			for i=1:obj.usedParams.featsPerClass
			
				% Find the feature which increases the distance the most to the previously selected features
				numUnselectedFeatures = length(unselectedFeatures);
				distances=zeros(1,numUnselectedFeatures);
				for j=1:numUnselectedFeatures
					tmpSelected = [selectedFeatures;unselectedFeatures(j)];
				
					classX = trainData.X(trainData.sampleLabels==c,tmpSelected);
					outClassX = trainData.X(trainData.sampleLabels~=c,tmpSelected);
					
					distances(j) = compute_distribution_mahalanobis_distance(classX, outClassX);
				end
				
				[~, bestIndex] = max(distances);
				selectedFeatures = [selectedFeatures;bestIndex];
				unselectedFeatures = setdiff(unselectedFeatures,bestIndex);
			end
			obj.allSelectedFeatures = [obj.allSelectedFeatures;selectedFeatures];	
		
			if(obj.usedParams.visualize)
				tit = sprintf('Feats for class %d (%s)', c, trainData.id);
				subplot(1,numClasses,c); imagesc(trainData.X(:,selectedFeatures)); title(tit);
				if(c==1)
					xlabel('Feature'); ylabel('Time');
				end
			end
			
		end
		
		%
		% @FIXME note that this may return the same features multiple times
		% (which is actually the behaviour the MD classifier needs as it assumes
		%  fixed amount of features per class)
		%
		
		% on demand
		feats = [];
	end
	
	function raw = process(obj, dataset)
		
		raw = dataset.X(:,obj.allSelectedFeatures);
			
	end
	
	end
	
end

