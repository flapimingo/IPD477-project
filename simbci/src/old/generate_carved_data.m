%
% Generate 'informationally simple' but 'spatially spread' data in volume and modulate at source dipoles
%
% Details. The idea of this generator is first to generate noise in the volume. The noise
% will be created only in sources and landmarks and then spread around to neighbouring
% dipoles with Gaussian weighting. This attemps to avoid the problem of having the
% noise in the volume informationally dense, as would be the case if we pulled
% all dipole activities of the volume from randn() or other distribution where
% dimensions are independent.
%
% After the noise has been generated, the sources of interest will have their
% activity dampened (carved) in a specified frequency band when the corresponding
% condition (class) is active. The carving resembles using a band-stop filter.
%
% Note: Due to the generation, the data will have at most sources+landmarks
% linearly independent dimensions, although there will be more active dipoles in total;
% these other dipole activity will be totally correlated with the generators.
%
% The noise in the distractors is introduced in this function in order to allow
% the 'smearing' effect affect the distractors as well as the sources.
%
function [S,generationROI, dipolesBetweenSources,d] = generate_carved_data(ref, S, genParams, sampleLabels, repeatedActivityMask, physicalModel)

% @fixme for nonconstrained orientations

	doSmearSourceActivity = true;
	addDistractors = true;
	doCarve = true;
	replicateSources = true;
	smearStrength = 0.01;

%%%%%% Select sources

	dipolesBetweenSources = 10;
	[generationROI,sources,d] = find_neighbours(ref, genParams.numberSources, dipolesBetweenSources, physicalModel);

%%%%% Select all generators

	if(addDistractors)
		% If this is active, data will be generated both in the ROI and some landmarks of the physical model
		allGens = unique([generationROI,physicalModel.centroids']);
	else
		% Data is only gerated in the ROI
		allGens = unique(generationROI);
	end

%%%% Generate noise

	params=[];
	params.power = 1.0;		    		                % 0 == disable
	params.exponent = 1.7;
	params.type='logunif'; % @fixme should be pink 1/f, but ica stops working if so?
	if(replicateSources)
		% In this case 'real' sources will all be clones of each other
		tmp = generate_noise([size(S,1) 1], params);
		S(:,generationROI) = repmat(tmp, [1 length(generationROI)]);
	else
		% Here all generators are independent
		S(:,generationROI) = generate_noise([size(S,1) length(generationROI)], params);
	end
	if(addDistractors)
		% distractors are always be independent from each other
		S(:,physicalModel.centroids') = generate_noise([size(S,1) length(physicalModel.centroids')], params);
	end

	% display_source_movie(S,physicalModel,allGens);

%%%% Modulate the sources - carve in the source activity

	if(doCarve)
		dof = length(sources) / genParams.numberSources; % num of dipoles per source

		for i=1:genParams.numberSources
			% The sources to be dampened are the ones active
			thisSource = sources((i-1)*dof+1:i*dof);

			% This is the signal with the band of interest removed
			Sfiltered = filter_bandstop(S(:,thisSource), genParams.samplingFreq, ...
				genParams.mi_centerHz - 3*genParams.mi_widthHz, genParams.mi_centerHz + 3*genParams.mi_widthHz, 60);

			% Generate an interpolation mask to mix filtered and original signal
			dampeningFactor = 1-genParams.mi_dampenFactors(i);
			weightedMask = repeatedActivityMask.*dampeningFactor;
			% each source is assumed to correspond to a class. Don't modulate any samples not in class
			outclassSamples = (sampleLabels~=i);
			weightedMask(outclassSamples) = 0;

			% Duplicate the mask to get it for all DOF
			replicatedMask = repmat( weightedMask, [1 length(thisSource)]);

			S(:, thisSource) = (1-replicatedMask) .* S(:, thisSource) + (replicatedMask .* Sfiltered);
		end
	end

%%%% Smear the source activity around the cortex.

	if(doSmearSourceActivity)
		S = smear_activity(S, allGens, physicalModel, smearStrength);
	end

	if(0)

		% TFR visualization
		pSpec = [];
		pSpec.extractorParams.MorletTFR = true;						 % Use TFR as Edelman/He, if false use spectrogram
		pSpec.extractorParams.TFRDownscaleFreq = 200;				 % Hz. Downscaled freq before TFR computation. The paper uses 100Hz
		pSpec.extractorParams.TFRFrequencyResolution = 0.5;			 % Hz. The paper uses 0.5 Hz
		pSpec.extractorParams.TFRFeatsTimeDuration = 250e-3;		 % ms; Used to average FTR feats into a more manageable number; paper uses 250ms
		pSpec.extractorParams.TFRFeatsFreqBin = 2;					 % Hz; Idem; paper uses 2Hz
		pSpec.extractorParams.featuresPerLabel = 5;				 % Number of feats to be extracted for each label. paper uses 13
		pSpec.extractorParams.FWHM = 3;								 % s; Full Width Half Maximum; paper uses 3
		pSpec.extractorParams.fc = 1;								 % Hz; central frequency of the wavelets. Paper uses 1 Hz but it looks like a typo, the TFRs don't look good
		pSpec.extractorParams.freqLow = 2;
		pSpec.extractorParams.freqHigh = 30;

		[TFRScaled,TFRFull] = compute_tfr_features(pSpec.extractorParams, S(:,allGens)', 200, 6, 56);
		imagesc(TFRFull);
		keyboard;

	end

	if(genParams.visualize)
		% Each source should have the dampening pattern visible, whereas other landmarks should be uniform
		figure();
		l=length(allGens);
		rows = ceil(sqrt(l));
		for i=1:l
			subplot(rows,rows,i);
			spectrogram(S(:,allGens(i)),80,20,[],genParams.samplingFreq);
			if(ismember(allGens(i), generationROI))
				tit=sprintf('Source %d', allGens(i));
			else
				tit=sprintf('Nonsource %d', allGens(i));
			end
			title(tit);
		end
	end
end

