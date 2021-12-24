

function feats = icaroi_extract(modelExtractor, dataset)

	XFiltered = filter_bandpass(dataset.X, dataset.samplingFreq, modelExtractor.params.freqLow, modelExtractor.params.freqHigh);

	% project the dada to volume
	sourceChannels = wmn_inverse(modelExtractor.modelA,XFiltered')';
	sourceChannels = sourceChannels(modelExtractor.modelICAROI,:);

	% Compute TFR features
	[TFRScaled,TFRFull] = compute_tfr_features(modelExtractor.params, sourceChannels, dataset.samplingFreq, dataset.trialLength, dataset.trials);

	% Select subset
	% N.b. Since here we have a subset of source channels, TFRScaled will already be correct
	feats = TFRScaled(:, modelExtractor.TFRFeatSpace);

	if(modelExtractor.params.visualize)
		t = sprintf('TFR Feature Channels (extract %s)', dataset.genParams.id);
		figure();imagesc(TFRScaled); title(t); ylabel('Trial'); xlabel('Feature');
		t = sprintf('MD selected TFR features (extract %s)', dataset.genParams.id);
		figure();imagesc(feats); title(t); ylabel('Trial'); xlabel('Feature');
		drawnow;
	end
