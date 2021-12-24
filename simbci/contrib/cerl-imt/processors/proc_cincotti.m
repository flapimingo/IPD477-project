
classdef proc_cincotti
	% 'Cincotti & al.' feature extractor based on inverse models
	%
	% Inspired by
	%
	% Cincotti & al. "High-resolution EEG techniques for braincomputer interface applications", 2008.
	% 
	% @author Jussi T. Lindgren / Inria based on the original code of CERL/IMT
	%
		
	properties
		ROIIndexes
		selectedFeatures
		inverseModel
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
		addParameter(p','ROISelection',           @roi_heuristic,   @isfunlist);     % Function to get ROI		
		addParameter(p, 'nFeatures',              2,                @isint);	 % total features = nFeatures*nClasses*2  (2 for taking both ends of corr)		
		addParameter(p, 'freqRes',                2,                @isnumeric); 		% FFT params, Hz		 
		addParameter(p, 'maxFreq',                60,               @isnumeric);		% FFT params, Hz
		addParameter(p, 'overlapRatio',           1/5,              @isnumeric);        % fft sliding window overlap
		addParameter(p, 'visualize',              false,            @islogical);	

		p.parse(varargin{:});
		params = p.Results;
		obj.usedParams = params;

		%%%%%%%%%%%

		% Setup the inverse model
		% @fixme refactor proc_cincotti to inherit from proc_inverse?
		obj.inverseModel = proc_inverse_transform().train(dataset,'forward',params.forward, ...
			'inverse',params.inverse,...
			'ROISelection',params.ROISelection, ...
			'visualize',params.visualize ...
		);
		
		%%%%%%%%%%%%

		% Extract all the features
		% Note that with the current design, the feats will contain the rest periods if used
		% the feats will be aligned [numFeats time], i.e. transpose of the usual machine learning convention
		feats = obj.cincotti_process_helper( trainData );
		
		% normalize to zero mean and unit variance. Note these should only be 
		% used for feature selection.
		normalizedFeats = normalize(feats,[],[],2);
		
		% Select features that are abs(correlated) with labels; we pick a number of feats per each class
		% @TODO this whole fft-power+correlation feature selection could be refactored as its own plugin 
		% in order to be used with other pipelines
		obj.selectedFeatures = [];
		for c=1:trainData.numClasses;
			inClassLabels = (trainData.sampleLabels==c); % trialLabels shouldn't be used as they don't have the rest class included
			inClassLabels = imresize(inClassLabels', [1 size(feats,2)], 'nearest');
			corrs = mean(bsxfun(@times, normalizedFeats, inClassLabels),2);
			[~, indexes] = sort(corrs,'descend');	% pick from both ends, so abs() not needed
			obj.selectedFeatures = [obj.selectedFeatures;indexes(1:params.nFeatures);indexes(end-params.nFeatures+1:end)];
		end

		% Remove possible duplicates; note due to this the amount of features may be different per run
		obj.selectedFeatures = unique(obj.selectedFeatures);
		
		% Normalized feats no longer needed, clear to get memory spike down asap
		clear normalizedFeats;
		
		feats = feats(obj.selectedFeatures,:)';
		% interpolate the FFT output to match the input size
	
		feats = imresize(feats, [size(trainData.X, 1) size(feats,2)], 'nearest');   
		
	end
	
	function feats = process(obj, dataset)
	% Extract features
		assert(~isempty(obj.inverseModel));
		
		% Extract all the features
		feats = obj.cincotti_process_helper( dataset );

		% Return a subset
		feats = feats(obj.selectedFeatures,:)';

		% interpolate the FFT output to match the input size
		feats = imresize(feats, [size(dataset.X, 1) size(feats,2)], 'nearest');    

	end
	
	end
	
	methods (Access = private)

	function [ featureMatrix ] = cincotti_process_helper( obj, dataset )
	%cincotti_process_helper Compute results common to training and online phases
		params = obj.usedParams;

		windowSize = 2 * params.maxFreq / (params.freqRes);

		slidingStep = round(windowSize * params.overlapRatio);

		SFeatures = obj.inverseModel.process(dataset)';
		
		% Returns a matrix which columns are the features for one sample
		% (num_freq_bins * ROI_sources)		
		[spectralFeatures, number_epochs] = sliding_fft(SFeatures, windowSize, slidingStep);
		
		% num_feats_per_epoch = size(spectralFeatures, 2) / number_epochs;
		%R2 = compute_r2_coefs(abs(spectralFeatures), trainData, number_epochs, 1:7, 8:14);
		% Reshaping for corrcoef -> one epoch per row
		featureVectorBlockSize = [size(spectralFeatures, 1) size(spectralFeatures, 2) / number_epochs];
		featureMatrix = im2col(spectralFeatures, featureVectorBlockSize, 'distinct');

		% Power transform
		featureMatrix = log(abs(featureMatrix));		
		%size(spectralFeatures, 1) / number_epochs

	end

	end

end

