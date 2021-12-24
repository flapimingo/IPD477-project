 

function [TFRFeatsScaled,TFRFeatsFull] = compute_tfr_features(params, sourceChannels, samplingFreq, trialLength,nTrials)

% the output feats(trial,features) matrix will have 2D spectral feature arrays packed as follows
%
% feats(1,:) = [vector(spectrum(channel1(trial1))),...,vector(spectrum(channelK(trial1))]
% feats(2,:) = [vector(spectrum(channel1(trial2))),...,vector(spectrum(channelK(trial2))]
%
% Note that there will only be as many vectors as there are trials,
% so to get good results, high trial count may be necessary. Or, the method
% could try to implement a sliding window approach like Cincotti, and assume
% that every window inside a trial can be classified according to the trial label.
		
	%% Computing the TFR Coefs	
	frequencyStep = params.TFRFrequencyResolution; %Hz
		
	% To reproduce the paper we need to downsample the signal to 100Hz
	fDownsampled = params.TFRDownscaleFreq; %Hz
	t = 0:(1/fDownsampled):(nTrials * trialLength); % time epochs
	% Centering t in 0
	t = t - t(end) / 2;
	t = t(1:end-1);
		
	% Only considering freqs, not filtered out
	f = params.freqLow:frequencyStep:params.freqHigh; % Frequencies
		
	PSI = get_morlet_coefs(t, f, params.FWHM, params.fc);
		
	%% Actual TFR computations
		
	nChannels = size(sourceChannels,1);
	samplesPerTrials = length(t) / nTrials;
				
	% We need to reduce the number of feats out of the TFR see detailed
	% version of the paper (10.1109/IMBC.2014.6943840) -> 250 ms time
	% windows and 2Hz freq bins
	newTFRTime = trialLength / params.TFRFeatsTimeDuration;
	newTFRBins = (params.freqHigh - params.freqLow) /...
	params.TFRFeatsFreqBin;
	featsPerTrial = newTFRTime * newTFRBins;
	
	featsPerTFR1 = size(PSI,1);
	featsPerTFR2 = size(PSI,2);
	
	TFRFeatsScaled = zeros(nTrials, featsPerTrial * nChannels);
	TFRFeatsFull = zeros(nChannels*featsPerTFR1, featsPerTFR2);
	
	for i=1:nChannels							% Loop over the source channels
		s = downsample_signal(sourceChannels(i,:), samplingFreq, fDownsampled);
		
		TFR = abs(compute_morlet_TFR(s, PSI));
		%figure(i);
		%imagesc(t, f, abs(TFR)); xlabel('t (s)'); ylabel('f (Hz)'); % Generates same plots as fig. 3.b of Edelman 2016
		TFRFeatsFull((i-1)*featsPerTFR1+1:i*featsPerTFR1,:) = TFR;
		for j=1:nTrials
			trialTFR = TFR(:, ((j-1) * samplesPerTrials + 1):j * samplesPerTrials);
			%imagesc(trialTFR);pause;
			features = imresize(trialTFR, [newTFRBins, newTFRTime], 'bilinear');
			TFRFeatsScaled(j, ((i-1) * featsPerTrial + 1):i * featsPerTrial) = features(:);
		end
	end
		
	%figure(); imagesc(tmp); title('Full TFR features'); drawnow;
	%figure(); imagesc(TFRFeats); title('Scaled TFR features'); drawnow; % the blur of in-class here from the sides is because of the packing
	
