
function model = icasimple_train(trainData, params)
% This is like the Edelman/He pipeline (icaroi_*.m), but instead of projecting into
% volume, the TFR features are directely extracted from those ICA components
% that best match the spectral template.

	assert(params.MorletTFR,'Assumes Morlet TFR');

	% Estimate ICA
	XFiltered = filter_bandpass(trainData.X, trainData.samplingFreq, params.freqLow, params.freqHigh);

	[weights,sphere,compvars,bias,signs,lrates,activations] = ...
		runica(XFiltered','pca',params.pcaDims, 'verbose', params.icaVerbose);
	assert(isreal(weights), 'ICA returned imaginary weighting');
	icaW = weights * sphere;		% Multiplication by 'sphere' is needed if PCA is not used (with pca, no effect)
	icaA = pinv(icaW);
	icaS = icaW * XFiltered';

	if(params.visualize & true)
		% debug block, this investigates if the ICA components are
		% correlated with the actual sources and if they pool more than one
		% source to the same component. Note for the display to work
		% nicely, at the moment there might be a need for not enabling the
		% source smearing. Without smear, use ICA only on the 'active
		% sources', find() below...
		actives = find(var(trainData.S)>0);
		datVolume = trainData.S(:,actives);
		[weights2,sphere2] = runica(datVolume','pca',params.pcaDims, 'verbose', params.icaVerbose);
		icaS2 = weights2 * datVolume';

		% On left, ICA components estimated from surface compared to true volume
		% On right, ICA -""- estimated from true volume compared to true volume (sanity check, e.g. for PCA destruction)
		co=corrcoef([datVolume,icaS']);
		co2=corrcoef([datVolume,icaS2']);
		figure();
		subplot(1,2,1); imagesc(abs(co)); title('ICA surf vs vol');
		subplot(1,2,2); imagesc(abs(co2)); title('ICA vol vs vol');
		drawnow;
	end

	% Compute how well each ICA component matches to a predefined mask (match in time/frequency power rep.)
	trialSamples = trainData.trialLength * trainData.samplingFreq;

	% generate a spectral template mask for the expected frequency
	% range and modulate it with the activity mask
	fs = params.freqLow:params.TFRFrequencyResolution:params.freqHigh; % Frequencies
	numTimeSamples = length(downsample_signal(zeros(1, trialSamples), trainData.samplingFreq, params.TFRDownscaleFreq));
	spectralTemplate = zeros(length(fs), numTimeSamples);
	spectralTemplate( (fs>=params.templateFreqLow & fs<=params.templateFreqHigh) , : ) = 1;

	% resize the activity mask to match the spectral template
	scaledMask = imresize( (1-trainData.trialActivityMask)', size(spectralTemplate),'nearest');
	spectralTemplate = spectralTemplate .* scaledMask;

	%% Compute the TFR Coefs
	[TFRScaled,TFRFull] = compute_tfr_features(params, icaS, trainData.samplingFreq, trainData.trialLength, trainData.trials);
	spectralFull = repmat(spectralTemplate,[1 trainData.trials]);

	% Find out which ICA channels best match the spectral template
	nRowsPerChannel = size(TFRFull,1)/size(icaS,1);
	scores=zeros(size(icaS,1),1);
	for i=1:size(icaS,1)	   				% Loop over estimated ICA components
		TFRChannelData = TFRFull((i-1)*nRowsPerChannel+1:i*nRowsPerChannel,:);

		co = corrcoef(spectralFull(:), TFRChannelData(:));
		scores(i) = co(1,2);
	end

	% Pick the best matching ICA components
	[dummy,componentIdx] = sort(scores,'descend');

	selectedComponents = sort(componentIdx(1:params.icaDims));

	% finally, extract the TFR features from the ICA components themselves

	% Pick TFR feat subset specific to the selected ICA components
	featsPerComponent = size(TFRScaled,2)/size(icaS,1);
	offsetPerComponent = (selectedComponents-1)*featsPerComponent;
	% component feature indexes = 1:nFeatures + offset(component)
	indexes = repmat(1:featsPerComponent,[length(selectedComponents) 1]) + repmat(offsetPerComponent, [1 featsPerComponent]);

	TFRFeats = TFRScaled(:,sort(indexes(:)));

	featSpaces = md_select_features(TFRFeats, trainData.numberClasses, trainData.trials / trainData.numberClasses, params.featuresPerLabel);

	if(params.visualize)
		figure(); imagesc([spectralFull;TFRFull./max(TFRFull(:))]); title('Spectral Template ; full ICA TFR (train)'); ylabel('Channel');xlabel('Time');
		figure(); imagesc(TFRScaled); title('Scaled TFR (train)');	ylabel('Trial'); xlabel('Feature');
		figure(); imagesc(TFRFeats); title('TFR Best Channels (train)'); ylabel('Trial'); xlabel('Feature');
		figure(); imagesc(TFRFeats(:,featSpaces)); title('MD selected TFR features (train)');  ylabel('Trial');xlabel('Feature');
		drawnow;
	end

	model.modelICASelected = selectedComponents;	% components selected
	model.TFRFeatSpace = featSpaces;				% features selected of the selected components
	model.modelICAW = icaW;
	model.params = params;
	% The following variables are not used later, but they may be useful for analysis
	model.modelICAA = icaA;
	model.modelICAScores = scores;
	model.modelSpectralTemplate = spectralTemplate;
	model.numberClasses = trainData.genParams.numberSources;


