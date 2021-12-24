
classdef proc_normalize
% Normalizes a dataset to zero mean and unit variance

	properties
		normalizeMean
		normalizeStd
	end
	methods

	function [obj,feats] = train(obj,trainData, varargin )
	% Train a normalization model

		[feats,me,sd] = normalize(trainData.X);

		obj.normalizeMean = me;
		obj.normalizeStd = sd;

	end


	function feats = process(obj, dataset)
	% Process new data
		assert(~isempty(obj.normalizeMean));

		feats = normalize(dataset.X, obj.normalizeMean, obj.normalizeStd);

	end

	end

end


