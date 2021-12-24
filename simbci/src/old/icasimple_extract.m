

function feats = icasimple_extract(modelExtractor, dataset)

	XFiltered = filter_bandpass(dataset.X, dataset.samplingFreq, modelExtractor.params.freqLow, modelExtractor.params.freqHigh);

	% project the dada
	icaS = modelExtractor.modelICAW(modelExtractor.modelICASelected,:) * XFiltered';

	% Compute TFR features
	[TFRScaled,TFRFull] = compute_tfr_features(modelExtractor.params, icaS, dataset.samplingFreq, dataset.trialLength, dataset.trials);

	% Select subset
	% N.b. Since here we already projected only a subset of ICA components, TFRScaled will already be correct
	feats = TFRScaled(:, modelExtractor.TFRFeatSpace);

	if(modelExtractor.params.visualize)
		t = sprintf('TFR Feature Channels (extract %s)', dataset.genParams.id);
		figure();imagesc(TFRScaled); title(t); ylabel('Trial'); xlabel('Feature');
		t = sprintf('MD selected TFR features (extract %s)', dataset.genParams.id);
		figure();imagesc(feats); title(t); ylabel('Trial'); xlabel('Feature');
		drawnow;
	end
