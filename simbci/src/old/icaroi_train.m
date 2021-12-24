
function [model,feats] = icaroi_train(trainData, params)
% This is like the Edelman/He pipeline (icaroi_*.m), but instead of projecting into
% volume, the TFR features are directely extracted from those ICA components
% that best match the spectral template.

	assert(params.MorletTFR,'Assumes Morlet TFR');

	% Estimate ICA
	XFiltered = filter_bandpass(trainData.X, trainData.samplingFreq, params.freqLow, params.freqHigh);

	[weights,sphere,compvars,bias,signs,lrates,activations] = ...
		runica(XFiltered','pca',params.pcaDims, 'verbose', params.icaVerbose);
	if(~isreal(weights))
		fprintf(1,'Warning: ICA returned imaginary weighting\n');
		weights = real(weights); sphere=real(sphere);
	end
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
		pcaDim = min(length(actives),params.pcaDims);
		[weights2,sphere2] = runica(datVolume','pca',pcaDim, 'verbose', params.icaVerbose);
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

	% @fixme: In the original paper, 75% of the strongest coeffs are kept. Here we keep a fixed number
	% per chosen ICA dim.
	selectedSources = [];
	ROIIndexes{2} = []; % Usefull if we don't have the same number of sources in all ROIs
	for i=1:params.icaDims
		% FIXME use WMN as in the paper?
		maskInVolume = sLORETA(physicalModel.A, icaA(:,selectedComponents(i)), physicalModel.constrainedOrientation);
		maskAbs = abs(maskInVolume);
		% FIXME for nonconstrained orientation?
		sourceIdx = find(maskAbs>params.activationThreshold*max(maskAbs(:)));
		ROIIndexes{i} = size(selectedSources, 1) + 1:size(selectedSources, 1) + params.maxSourcesPerIcaDim;
		selectedSources = union(selectedSources,sourceIdx);

		tit = sprintf('Selected sources for ICA component %d: %d', i, selectedComponents(i));
	if(params.visualize)
		figure(); visualize_physicalmodel(physicalModel, sourceIdx, [], true); title(tit);
	end
	end

	if(params.visualize)
		figure(); visualize_physicalmodel(physicalModel, selectedSources, [], true); title('Union of selected sources');
	end

	% finally, extract the TFR features from the volume

	% time frequency representation, Edelman/He paper page 8
	% make the a TFR for each trial
	sourceChannels = wmn_inverse(physicalModel.A,XFiltered')';
	sourceChannels = sourceChannels(selectedSources,:);

	[TFRScaledVolume,TFRFullVolume] = compute_tfr_features(params, sourceChannels, trainData.samplingFreq, trainData.trialLength, trainData.trials);

	featSpaces = md_select_features(TFRScaledVolume, trainData.numberClasses, trainData.trials / trainData.numberClasses, params.featuresPerLabel);

	if(params.visualize)
		figure(); imagesc([spectralFull;TFRFull./max(TFRFull(:))]); title('Spectral Template ; full ICA TFR (train)'); ylabel('Channel');xlabel('Time');
		figure(); imagesc(TFRScaled); title('Scaled ICA TFR (train)');	ylabel('Trial'); xlabel('Feature');
		figure(); imagesc(TFRScaledVolume); title('Scaled Volume TFR (train)');	ylabel('Trial'); xlabel('Feature');
		figure(); imagesc(TFRScaledVolume(:,featSpaces)); title('MD selected Volume TFR features (train)');  ylabel('Trial');xlabel('Feature');
		drawnow;
	end

	model.modelICAROI = selectedSources;	    % source selected in the volume
	model.TFRFeatSpace = featSpaces;				% features selected of the selected components
	model.modelA = physicalModel.A;
	model.modelICAW = icaW;
	model.params = params;
	% The following variables are not used later, but they may be useful for analysis
	model.modelICAA = icaA;
	model.modelICAScores = scores;
	model.modelSpectralTemplate = spectralTemplate;
	model.numberClasses = trainData.genParams.numberSources;

	feats = [];

