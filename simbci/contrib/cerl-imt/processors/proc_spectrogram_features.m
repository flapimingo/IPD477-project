
classdef proc_spectrogram_features
% Extract FFT Spectrogram type features computed with sliding FFT
%
% @FIXME this class misbehaves in a way that the returned amount of features
% matches neither sample or trial counts. proc_interpolate_data.m can be used
% to remedy this. We don't rescale the features internally here as that would lead to 
% differing performances of the 'modular' and 'monolithic' Cincotti pipelines;
% for efficiency reasons the latter scales features only after feature selection
% (which we dont do internally in this class).
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

		addParameter(p, 'call',                   @proc_spectrogram_features,  @isfun);  % not really used, just to allow passing the param 	
		addParameter(p, 'freqRes',                2,                @isnumeric); 		% FFT params, Hz		 
		addParameter(p, 'maxFreq',                60,               @isnumeric);		% FFT params, Hz
		addParameter(p, 'overlapRatio',           1/5,              @isnumeric);        % fft sliding window overlap
		addParameter(p, 'visualize',              false,            @islogical);
		addParameter(p, 'logEps',                 0,                @isnumeric);
		
		p.parse(varargin{:});
		obj.usedParams = p.Results;

		%%%%%%%%%%%
		
		% only extract on demand
		feats = [];
			
	end
	
	function feats = process(obj, dataset)
	% Extract features
		assert(~isempty(obj.usedParams));
		
		% Extract all the features
		feats = obj.extract_features( dataset )';
		
		% interpolate the FFT output to match the input size
		% feats = imresize(feats, [size(dataset.X, 1) size(feats,2)], 'nearest');    

	end
	
	end
	
	methods (Access = private)

	function [ featureMatrix ] = extract_features( obj, dataset )

		windowSize = 2 * obj.usedParams.maxFreq / (obj.usedParams.freqRes);

		slidingStep = round(windowSize * obj.usedParams.overlapRatio);

		% Returns a matrix whose columns are the features for one sample
		% (num_freq_bins * X_channels)
		[spectralFeatures, number_epochs] = sliding_fft(dataset.X', windowSize, slidingStep);
		
		% Reshaping for corrcoef -> one epoch per row
		featureVectorBlockSize = [size(spectralFeatures, 1) size(spectralFeatures, 2) / number_epochs];
		featureMatrix = im2col(spectralFeatures, featureVectorBlockSize, 'distinct');

		% Power transform
		featureMatrix = log(abs(featureMatrix)+obj.usedParams.logEps);

		%size(spectralFeatures, 1) / number_epochs

	end

	end

end

