%
% See README.TXT
%
% NB this file is pretty much just duplicate of classifytest. refactor to parts that are common and that vary
%
clear;
close all;

addpath(sprintf('%s/', cd));
addpath(sprintf('%s/utils', cd));
addpath(sprintf('%s/classifiers', cd));
addpath(sprintf('%s/extractors', cd));
addpath(sprintf('%s/inverse_algorithms', cd));
addpath(sprintf('%s/inverse_algorithms/details', cd));

addpath(sprintf('%s/packages/glmnet_matlab', cd));               % Feature selection by Generalized Linear Models & Lasso
addpath(sprintf('%s/packages/liblinear-2.1/windows', cd));       % Feature selection by L1 SVM. For non-windows platforms, needs a compile
addpath(sprintf('%s/packages/eeglab_ica/', cd));				 % Infomax Independent Component Analysis from the EEGLAB package
addpath(sprintf('%s/cincotti_details', cd));

% Misc
addpath('colormaps');
set(0,'DefaultFigureColormap',feval('inferno'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

iterations = 2;

disableAllPlots = false;						% When setting some plot as enabled below, use (true & ~disableAllPlots)
saveFigures = true;								% Write all open figs to pics/ after end of run

debugIfAccuracyBelow = 0.0;						% if test accuracy lower than this, breakpoint

% Params related to generating train data in the volume
generateParams=[];
generateParams.id='train';
generateParams.type='carve';					% What generator to use (bcicompiv paper 4.2.3, 4.2.4, 4.2.5)
generateParams.numberSources = 4;               % Number of MI sources
generateParams.trials = 56;					% Number of left, right graz motor imagery trials. Needs to be even.
generateParams.trialLength = 6;					% Trial length in seconds
generateParams.samplingFreq = 200;
generateParams.mi_centerHz = 12;				% Freq center for the motor imagery "mu" Event Related Depression (ERD) phenomenon
generateParams.mi_widthHz  = 1;
generateParams.mi_harmonicWeight = 0.00;		% Weight of the first harmonic of the mu ERD (in beta band), 0 == disable harmonic
generateParams.mi_dampenFactors =...
   ones(generateParams.numberSources, 1) * 0.1; % list of dampen factors for all sources (see description below).
generateParams.idleEnabled = true;				% Restrict modulation in trial to time range [trialStart+idle,trialEnd-idle]? Needed for Edelman/He.
generateParams.idleSecs = 1;					% Duration of idle at the beginning and end of trial. 0.5 = half a second.
generateParams.exponent = 1.7;					% How to scale the spectrum with 1/(f^exponent) law
generateParams.visualize = true & ~disableAllPlots;

% Params used for generating test data in the volume. Should resemble train data generation.
generateParamsTest = generateParams;
generateParamsTest.id = 'test';
generateParamsTest.trials = 56;					% we can have more trials in test to get more robust accuracy estimates

% Params related to importing physical models
physicalModelParams = [];
physicalModelParams.centerAndScale = true;		% Normalize the leadfield? (see code)
physicalModelParams.visualize = false;
physicalModelParams.adhocLandmarks = 5;			% Ad-hoc computation of cortical landmarks. Note: result may change between runs

% Params related to forward transform
forwardParams = [];
forwardParams.type = 'basic';
forwardParams.visualize = false;

% Params related to additive volumetric noise
volumeNoiseParams={};
volumeNoiseParams{1}.power = 0.000;        	    % 0 == disable
volumeNoiseParams{1}.type='bcicomp4-artifacts';    % bcicomp iv paper 4.2.6                %
volumeNoiseParams{1}.eyeblinkFrequency = 0.1;		% generating frequency of eyeblink events per second, 0 == disable
volumeNoiseParams{1}.eyeMoveFrequency = 0.2;		% generating frequency of eye movement events per second
volumeNoiseParams{1}.samplingFreq = generateParams.samplingFreq;
volumeNoiseParams{1}.sourceFile='';
volumeNoiseParams{1}.exponent = 1.7;
volumeNoiseParams{1}.visualize = false;
volumeNoiseParams{2}.power = 0.000;             	    % 0 == disable
volumeNoiseParams{2}.type='distractors';
volumeNoiseParams{2}.distractorNoiseType = 'logunif';	% the distractor sources have this distribution
volumeNoiseParams{2}.samplingFreq = generateParams.samplingFreq;
volumeNoiseParams{2}.visualize = true & ~disableAllPlots;;

% Params related to additive surface noise.
% Note that in bcicomp4, baseline activity coming from the volume is modeled as additive surface noise noise.
surfaceNoiseParams={};
surfaceNoiseParams{1}.power = 0.01;		    		                % 0 == disable
surfaceNoiseParams{1}.type='pink';
surfaceNoiseParams{1}.strength = [1.0, 0.5, 0.3];                  % Strengths for the bg noise, and drift 1 and drift 2, respectively
surfaceNoiseParams{1}.samplingFreq = generateParams.samplingFreq;
surfaceNoiseParams{1}.exponent = 1.7;
surfaceNoiseParams{1}.visualize = true & ~disableAllPlots;

% Specification of classification pipelines to be tested.
allPipelines=[];

if(1)

pSpec = [];
pSpec.name = 'csp-bandpower-lda';
pSpec.extractorParams.type = 'csp_bandpower';
pSpec.extractorParams.extractTrials = false;
pSpec.extractorParams.logFeats = true;
pSpec.extractorParams.freqLow = 8;
pSpec.extractorParams.freqHigh = 30;
pSpec.extractorParams.csp_dim = 2;
pSpec.extractorParams.csp_tikhonov = 0.5;
pSpec.extractorParams.csp_shrink = 0.5;
pSpec.extractorParams.visualize = false;
pSpec.extractorParams.normalize = true;
pSpec.classifierParams.type = 'lda';
pSpec.classifierParams.tikhonov = 0;
pSpec.classifierParams.shrink = 0;
pSpec.classifierParams.quadratic = false;
pSpec.pruneOutlierPercent = 0.0;
pSpec.visualize = false;
allPipelines = [allPipelines ; pSpec];

end

if(0)

pSpec = [];
pSpec.name = 'edelman-simple';								% Edelman/He pipeline using 'time frequency representation'
pSpec.extractorParams.type = 'icaroi';
pSpec.extractorParams.timeFrequencyFeaturesDownscale = true; % only when using spectogram instead of morelet
% Morelet TFR params
pSpec.extractorParams.MorletTFR = true;						 % Use TFR as Edelman/He, if false use spectrogram
pSpec.extractorParams.TFRDownscaleFreq = 100;				 % Hz. Downscaled freq before TFR computation. The paper uses 100Hz
pSpec.extractorParams.TFRFrequencyResolution = 0.5;			 % Hz. The paper uses 0.5 Hz
pSpec.extractorParams.TFRFeatsTimeDuration = 250e-3;		 % ms; Used to average FTR feats into a more manageable number; paper uses 250ms
pSpec.extractorParams.TFRFeatsFreqBin = 2;					 % Hz; Idem; paper uses 2Hz
pSpec.extractorParams.featuresPerLabel = 5;				 % Number of feats to be extracted for each label. paper uses 13
pSpec.extractorParams.FWHM = 3;								 % s; Full Width Half Maximum; paper uses 3
pSpec.extractorParams.fc = 10;								 % Hz; central frequency of the wavelets. Paper uses 1 Hz but it looks like a typo, the TFRs don't look good
% End Morelet TFR params
pSpec.extractorParams.extractTrials = true;					 % true: 1 trial = 1 feature vector
pSpec.extractorParams.logFeats = false;
pSpec.extractorParams.freqLow = 2;
pSpec.extractorParams.freqHigh = 30;
pSpec.extractorParams.visualize = true & ~disableAllPlots;
pSpec.extractorParams.icaVerbose = 'on';					 % 'on' will show some convergence statistics
pSpec.extractorParams.pcaDims = 5;							 % we may need to reduce dim with PCA to get better ICA components, esp. in low noise cases (max value: num of surface electrodes)
pSpec.extractorParams.icaDims = 4;							 % since our MI has indep. left and right cortical side, makes sense to pick 2 ICA components (Edelman/He use just 1).
pSpec.extractorParams.maxSourcesPerIcaDim = 5;				 % UNUSED For each ICA dim (component) selected, how many strongest volumetric sources to take into the ROI from it.
pSpec.extractorParams.activationThreshold = 0.75;		     % percentage of max to keep
pSpec.extractorParams.templateFreqLow = 8;					 % Params for the frequency mask template used to select the ICA components
pSpec.extractorParams.templateFreqHigh = 13;
pSpec.extractorParams.normalize = false;
pSpec.classifierParams.type = 'md_classifier';
pSpec.pruneOutlierPercent = 0.0;
pSpec.visualize = false & ~disableAllPlots;
allPipelines = [allPipelines ; pSpec];

end

% Physical models doing the mapping between volume<->surface. Should include positions on surface and volume.
%physicalModels = {'models/brain/OculusdataBeautifulBrainLight.mat','models/sphere/leadfield_256elec_sigma15'};
%physicalModels = {'models/sphere/leadfield_256elec_sigma15'};
physicalModels = {'models/brain/OculusdataBeautifulBrainLight.mat'};
%physicalModels = {'models/sphere/leadfield_256elec_sigma15'};
% physicalModels = {'models/sphere/leadfield_256elec_sigma15','models/head/leadfield_another'};

% Accuracies over runs for the different combinations
results = containers.Map;

% Time spent generating data
generationTime = zeros(length(physicalModels),iterations);

% Loop over all our known physical models
for m = 1:length(physicalModels)
	modelFile = char(physicalModels(m));

	fprintf(1, 'Model %s ...\n', modelFile);

	% Load the physical model from file (leadfield, topology, whatever ...)
	physicalModel = load_physical_model(modelFile, physicalModelParams);

	% Do a certain amount of repetitions to get a smoother accuracy estimate.
	for i=1:iterations
		fprintf(1, '  Iteration %02d / %02d ... Generating data... ', i, iterations);

		% May avoid memory use peaks a little ...
		clear trainData testData pipeline;

		% Generate independent train and test sets
		tic;

		trainData = generate_volume_data(physicalModel, generateParams);
		trainData.S = trainData.S + generate_noise_list(size(trainData.S), volumeNoiseParams, physicalModel);
		trainData.X = forward_transform(physicalModel, trainData.S, forwardParams);
		trainData.X = trainData.X + generate_noise_list(size(trainData.X), surfaceNoiseParams, physicalModel);

		testData = generate_volume_data(physicalModel, generateParamsTest);
		testData.S = testData.S + generate_noise_list(size(testData.S), volumeNoiseParams, physicalModel);
		testData.X = forward_transform(physicalModel, testData.S, forwardParams);
		testData.X = testData.X + generate_noise_list(size(testData.X), surfaceNoiseParams, physicalModel);

		generationTime(m,i) = toc;

		% Each pipeline corresponds to some combination of feature extraction + classification
		for p = 1:length(allPipelines)
			fprintf(1, '%s ... ', allPipelines(p).name);

			% Train a classifying pipeline. All info needed to do classification must be stored in 'pipeline' by the function.
			tic;
			pipelineTrained = train_pipeline(physicalModel, trainData, allPipelines(p));
			estimationTime = toc;

			% Classify train data. Mostly for debugging purposes.
			tic;
			trainPredictions = test_pipeline(pipelineTrained, trainData);
			trainAccuracy = mean(trainPredictions==trainData.trialLabels);

			% Classify new data. Note that test_pipeline() should NOT use labels from testData!
			testPredictions = test_pipeline(pipelineTrained, testData);
			testAccuracy = mean(testPredictions==testData.trialLabels);
			if(testAccuracy<debugIfAccuracyBelow)
				fprintf(1,'Test accuracy is %f, debug ...	\n', testAccuracy);
				keyboard
			end

			evaluationTime = toc;

			% Append the results of the pipeline to a corresponding map entry
			key = sprintf('%s_%s', modelFile, allPipelines(p).name);
			if(~isKey(results,key))
				thisRes = [];
				thisRes.testAccuracy = zeros(1,iterations);
				thisRes.trainAccuracy = zeros(1,iterations);
				thisRes.estimationTime = zeros(1,iterations);
				thisRes.evaluationTime = zeros(1,iterations);
				results(key) = thisRes;
			end

			thisRes = results(key);
			thisRes.testAccuracy(i) = testAccuracy;
			thisRes.trainAccuracy(i) = trainAccuracy;
			thisRes.estimationTime(i) = estimationTime;
			thisRes.evaluationTime(i) = evaluationTime;
			results(key) = thisRes;
		end

		save('backup.mat','generateParams','forwardParams','volumeNoiseParams','surfaceNoiseParams','allPipelines','results','generationTime');

		fprintf(1,'\n');

	end

end

% Print average results across iterations

allKeys = keys(results);

fprintf(1,'Avg time spent: \n');
for i=1:length(allKeys)
	thisRes=results(char(allKeys(i)));
	fprintf(1, '  %s - estimation %.2fs (%.2fs/trial), testing %.2fs (%.2fs/trial)\n', ...
		char(allKeys(i)), ...
		mean(thisRes.estimationTime), mean(thisRes.estimationTime)/generateParams.trials, ...
		mean(thisRes.evaluationTime), mean(thisRes.evaluationTime)/generateParamsTest.trials ...
		);
end

for i=1:length(physicalModels)
	fprintf(1,'  Data generation: %s - %.2fs per set\n', char(physicalModels(i)), mean(generationTime(i,:)));
end

fprintf(1,'Train accuracy results: \n');
for i=1:length(allKeys)
	thisRes=results(char(allKeys(i)));
	fprintf(1, '  %s - mean %.2f var %.2f min %.2f\n', char(allKeys(i)), mean(thisRes.trainAccuracy), var(thisRes.trainAccuracy), min(thisRes.trainAccuracy));
end

fprintf(1,'Test accuracy results: \n');
for i=1:length(allKeys)
	thisRes=results(char(allKeys(i)));
	fprintf(1, '  %s - mean %.2f var %.2f min %.2f\n', char(allKeys(i)), mean(thisRes.testAccuracy), var(thisRes.testAccuracy), min(thisRes.testAccuracy));
end

if(saveFigures & ~disableAllPlots)
	fprintf(1, 'Saving figs to pics/ ...');
	delete('pics/*.png');
	figHandles = get(0,'Children');
	for i=1:length(figHandles)
		h = get(figHandles(i));
		fn = sprintf('pics/debug%03d.png', h.Number);
		print(h.Number,'-dpng','-r300',fn);
		fprintf(1,'.');
	end
	fprintf(1,' done\n');
end

if(false & ~disableAllPlots)
	% nb generally its better to do plotting in each corresponding component as there
	% might be a better idea *locally* what to plot...

	% assuming last classifier is glmnet, show the sources it chose ...
	if(0)
		coefs = cvglmnetCoef(pipeline.modelClassifier);
		coefs = coefs(2:end); % the 1st glmnet coef is the intercept, drop that
		visualize_physicalmodel(physicalModel, find(coefs~=0));
		title('Sources selected by glmnet');
	end

	% assuming last classifier is liblinear with sloreta, show the sources it chose ...
	if(0)
		coefs = pipeline.modelClassifier.w;
		visualize_physicalmodel(physicalModel, find(coefs~=0), [], true);
		title('Sources selected by liblinear');
	end
end


save('results.mat','generateParams','forwardParams','volumeNoiseParams','surfaceNoiseParams','allPipelines','results');

