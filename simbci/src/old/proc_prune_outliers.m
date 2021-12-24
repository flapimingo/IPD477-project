
classdef proc_prune_outliers
% @FIXME to be implemented

	properties

	end
	methods

	function [obj, feats] = train(obj, trainData, varargin )

		assert(false, 'Implementation missing');

		if(0)
			% @FIXME a working implementation requires ability to pass
			% out the modified labels
			if(nargin<3)
				percent = 0.02;
			end

			if(percent>0)
				% Remove outliers (training examples with extremal values in some
				% dim) by replacing with a sample of other examples. This has the benefit
				% over simple removal that the dataset size doesn't change.
				numExamples = size(XFeatures,1);
				numResampled = floor(percent * numExamples);
				[m,midx] = max(abs(XFeatures),[],2);
				[s,sidx] = sort(m,'descend');
				outlierIdx = sidx(1:numResampled);
				availableIdx = setdiff(1:numExamples, outlierIdx)';
				resampleIdx = availableIdx( randi(length(availableIdx), [numResampled 1]) );

				XFeatures(outlierIdx,:) = XFeatures(resampleIdx,:);
				labels(outlierIdx) = labels(resampleIdx);
			end
		end
	end

	function feats = process(obj, dataset)
		feats = dataset.X;
	end

	end
end

