

classdef proc_tfr
% Computes Time/Frequency Representation (TFR) of the dataset
%
% Uses Morlet wavelets to generate the representation. For each input
% channel, a set of features are created. The resulting number of features
% per channel is the length of the freqLow:freqStep:freqHigh array.
%
% The output is the result of the morlet wavelet bank convoluted 
% with the signal, followed by abs().
%
% @author Jussi T. Lindgren / Inria based on the original code of CERL/IMT
%
	properties
		usedParams
	end
	methods
		
	function [obj,feats] = train(obj, trainData, varargin)
	% Trains the feature extractor

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'freqStep',                0.5,         @isnumeric); % The frequency resolution step, smaller=finer freq grid.
		%addParameter(p, 'TFRFeatsTimeDuration',   250e-3,       @isnumeric); % ms; Used to average FTR feats into a more manageable number
		%addParameter(p, 'TFRFeatsFreqBin',           2,         @isnumeric); % Hz; Idem
		addParameter(p, 'freqLow',                   8,         @isnumeric);
		addParameter(p, 'freqHigh',                 13,         @isnumeric);			
		addParameter(p, 'FWHM',                      3,         @isnumeric); % Morlet params
		addParameter(p, 'fc',                       10,         @isnumeric); % Morlet params
		addParameter(p, 'scaled',                false,         @islogical);
		addParameter(p, 'visualize',             false,         @islogical);
		
		p.parse(varargin{:});
		obj.usedParams = p.Results;

		%%%%%%%
			
		feats = [];
	end

	function feats = process(obj, dataset)
	% n.b. this is a bit optimistic as the used convolution 'sees' the future.
	
		[numSamples,numChannels] = size(dataset.X);
		
		% sample times
		t = (0:numSamples)/dataset.samplingFreq; 
		t = t - t(end) / 2; 		% Centering t around 0
		t = t(1:end-1);
		
		% Only considering these freqs
		f = obj.usedParams.freqLow:obj.usedParams.freqStep:obj.usedParams.freqHigh;
		
		% Get the wavelet filter bank
		PSI = get_morlet_coefs(t, f, obj.usedParams.FWHM, obj.usedParams.fc);

		numFeatsPerChannel = size(PSI,1);
		assert(size(PSI,2)==numSamples);
		
		%% Actual TFR computations. Each column of 'feats' will be an abs wavelet response
		%% for a [src chn, wavelet hz] pair.
		feats = zeros(numSamples,numChannels*numFeatsPerChannel);
		cnt = 1;
		for i=1:numChannels
			for j=1:numFeatsPerChannel
				feats(:,cnt) = abs(conv(dataset.X(:,i)', PSI(j,:), 'same'));
				cnt = cnt + 1;
			end
		end

		% @todo add rescaling here; alternatively we can just downsample the feats signal further after
		
		if(obj.usedParams.visualize)
			t = sprintf('TFR Feature Channels (extract %s)', dataset.id);
			figure();imagesc(feats); title(t); ylabel('Time'); xlabel('Feature');
			drawnow;
		end

	end

	end % methods
end
	