
classdef proc_correlation_selector
% Simple feature selection that is based on computing correlation between 
% each feature and the binarized class labels (e.g. for each class, set
% all labels to 1 if the class matches, and 0 otherwise. Then 
% compute the correlation between this vector and each feature, and pick 
% a few strongly positively and negatively correlated features). The returned
% total feature set is an union of the per-class features.
%
	properties
		selectedFeatures
		featureScores                    % just for diagnosis
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

		addParameter(p, 'call',                   @proc_correlation_selector,  @isfun);  % not really used, just to allow passing the param 	
		addParameter(p, 'nFeatures',              2,                @isint);	 % total features = nFeatures*nClasses*2  (2 for taking both ends of corr)
		addParameter(p, 'visualize',              false,            @islogical);

		p.parse(varargin{:});
		obj.usedParams = p.Results;

		%%%%%%%%%%%

		% normalize to zero mean and unit variance. Note these should only be 
		% used for feature selection and not returned.
		normalizedFeats = normalize(trainData.X,[],[],1);
		
		% Select features that are abs(correlated) with labels; we pick a number of feats per each class
		obj.selectedFeatures = [];
		obj.featureScores = [];
		for c=1:trainData.numClasses;
			inClassLabels = (trainData.sampleLabels==c); % trialLabels shouldn't be used as they don't have the rest class included
			% address issue of feature and label sizes not always matching, this indicates a problem/feature of upstream feature extractor
			inClassLabels = imresize(inClassLabels, [size(normalizedFeats,1) 1],'nearest'); 
			corrs = mean(bsxfun(@times, normalizedFeats, inClassLabels),1);
			[scores, indexes] = sort(corrs,'descend');	% pick from both ends, so abs() not needed
			obj.selectedFeatures = [obj.selectedFeatures;indexes(1:obj.usedParams.nFeatures)';indexes(end-obj.usedParams.nFeatures+1:end)'];
			obj.featureScores = [obj.featureScores;scores(1:obj.usedParams.nFeatures)';scores(end-obj.usedParams.nFeatures+1:end)'];
		end

		% Remove possible duplicates; note due to this the amount of features may be different per run
		[obj.selectedFeatures,selIdx] = unique(obj.selectedFeatures);
		obj.featureScores = obj.featureScores(selIdx);
		
		% Only return feats on demand
		feats = [];	
		
	end
	
	function feats = process(obj, dataset)
	% Extract features
		assert(~isempty(obj.selectedFeatures));
		
		% Return a subset
		feats = dataset.X(:,obj.selectedFeatures);
		
		if(obj.usedParams.visualize)
			% flip features with neg correlations for visualization
			%negFeats = (obj.featureScores<0);
			%tmpFeats = feats;
			%tmpFeats(:,negFeats) = -tmpFeats(:,negFeats);
		
			tit = sprintf('%s - Feats from correlation selector', dataset.id);
			figure(); imagesc(normalize(feats)); title(tit); drawnow;
		end
	end

	end

end

