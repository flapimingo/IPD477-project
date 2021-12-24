
classdef proc_interpolate_data
% Interpolate data to match original dataset size
%
% Feature extractors may return datasets where the size matches
% neither trial or sample count. This class can be used as a processing
% stage to interpolate the data to match the original sample or trial
% count. It uses nearest neighbour interpolation to avoid long-distance
% effects over time.

	properties
		usedParams
	end
	methods

	function [obj, feats] = train(obj, ~, varargin )
	% Train the feature extractor

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'toSamples',              true,              @islogical);	% if false, interpolate to trials

		p.parse(varargin{:});
		obj.usedParams = p.Results;

		%%%%%

		% only extract on demand
		feats = [];
	end

	function feats = process(obj, dataset)
	% Extract features

		if(obj.usedParams.toSamples)
			feats = imresize(dataset.X, [size(dataset.trialIds,1) size(dataset.X,2)], 'nearest');
		else
			feats = imresize(dataset.X, [dataset.numTrials, size(dataset.X,2)], 'nearest');
		end

	end

	end

end

