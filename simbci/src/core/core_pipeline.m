

classdef core_pipeline
	% CLASS_PIPELINE Represents a signal processing pipeline in the framework.
	%
	% The pipeline consists
	% of a list of processors. The processors are ran in order sequentially, so
	% the output of a processor #1 is fed to the processor #2 as input etc. Each
	% processor is required to be a class with the member functions train() and process().
	% A simple example of a processor is 'proc_normalize.m'. If training is not
	% required for the processor, the train member function can be NOP.
	% Conceptually, if a processorList is {@a,@b,@c} the output of the
	% pipelines process call for dataset x is c.process(b.process(a.process(x))).
	% Training is done correspondingly.

	properties
		processorList
		generatingCall
		generatingVersion
		generatingDate

		usedParams
	end

	methods

	function obj = core_pipeline( varargin )
	% Default constructor

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'name',                     'anon',  @ischar);
		addParameter(p, 'visualize',              false,   @islogical);
		addParameter(p, 'processors',             {},      @iscell);
		addParameter(p, 'classEvents',            {},      @iscell); % which events are we interested in
		
		p.parse(varargin{:});
		obj.usedParams = p.Results;

		if(isempty(obj.usedParams.classEvents))
			fprintf(1,'Warning: you didnt specify which events mark trials to classify.\n');
		end
	end

	function obj = train(obj, trainData)
	% Train a classification pipeline consisting of a set of processors

		params = obj.usedParams;

		%%%%%%%%%%%%%

		% Append the dataset with some auxiliary stuff
		
		if(params.visualize)
			if(~isempty(trainData.S))
				t = sprintf('Received train data, volume (id %s)', trainData.id);
				figure();imagesc(trainData.S); title(t);  ylabel('Sample'); xlabel('Measurement');
			end
			t = sprintf('Received train data, surface (id %s)', trainData.id);
			figure();imagesc(trainData.X); title(t); ylabel('Sample'); xlabel('Measurement');
			drawnow;
		end
		
		trainData = obj.augment_dataset(trainData);

		% Make sure that possible volume data in trainData is not cheated with
		trainData.S = [];
		trainData.ROI = [];

		% Train the actual processing pipeline
		obj = obj.train_processors(trainData, params.processors{:}) ;

		obj.generatingCall = obj.get_params();
		obj.generatingVersion = platform_version();
		obj.generatingDate = datestr(now(),30);

	end

	function raw = process(obj, testData)
	% Return the output of the pipeline as-is without any further transformations
	% or assumptions about correspondence to trial/labels counts

		% Make sure pipelines don't use information that shouldn't be available.
		% Due to copy-on-write in Matlab, this should not be expensive
		if(~isfield(testData,'trialLabels'))
			testData = obj.augment_dataset(testData);
		end
		testData.trialLabels = [];
		testData.sampleLabels = [];
		testData.S = [];
		testData.ROI = [];

		raw = obj.run_processors(testData, obj.processorList);
	end

	function [predictions,rawPredictions,trueLabels] = predict(obj, testData)
	% Classify data using a pre-estimated pipeline. The last processor of the pipeline
	% executed by this function is expected to return a matrix of 'class likelihood'
	% of size [nRows,nClasses], where nRows must match either the number of trials or
	% the number of samples in testData.
	%
	% The function outputs one class label per trial in 'predictions' and
	% a matrix of class likelihoods og size [nTrials,nClasses] in 'rawPredictions'.
	%
		assert(~isempty(obj.processorList));

		if(obj.usedParams.visualize)
			if(~isempty(testData.S))
				t = sprintf('Received test data, volume (id %s)', testData.id);
				figure();imagesc(testData.S); title(t);   ylabel('Sample'); xlabel('Measurement');
			end
			t = sprintf('Received test data, surface (id %s)', testData.id);
			figure();imagesc(testData.X); title(t);   ylabel('Sample'); xlabel('Measurement');
			drawnow;
		end

		testData = obj.augment_dataset(testData);
				
		% get the class likelihoods
		rawPredictions = obj.process(testData);
		
		assert( (size(rawPredictions,1) == testData.numTrials) || (size(rawPredictions,1) == size(testData.X,1)), ...
			'Number of predictions from the pipeline doesnt match either sample or trial count');

		% If the classifier returned label per sample, aggregate these to match the trials.
		if(size(rawPredictions,1) == size(testData.X,1))
			% note: there's a design choice here between 1) aggregate first,
			% and threshold later, or 2) the opposite way around.
			% Currently we do #1.

			inTrialSamples = (testData.sampleLabels>0);

			% first, take only predictions related to non-rest trials (rest: class label==0)
			rawPredictions = rawPredictions(inTrialSamples,:);

			% Then aggregate each block to a prediction for the trial. Note the
			% previous solution of bilinear imresize() mixes across trials improperly and shouldn't be used.
			trialIds = testData.trialIds(inTrialSamples);
			if(exist('splitapply','file'))
				rawPredictions = splitapply(@mean, rawPredictions, trialIds);
			else
				% older matlab
				rawPredictions = mysplitapply(@mean, rawPredictions, trialIds);
			end
		end

		% If the output is a likelihood array, map it to labels
		[~,predictions] = max(rawPredictions,[],2);

		% Reasoned from the events by augment
		trueLabels = testData.trialLabels;
		
		if(obj.usedParams.visualize)
			figure();
			imagesc(rawPredictions); title(sprintf('Raw predictions (%s)', testData.id));
			xlabel('Class'); ylabel('Time');
		end

	end

	function paramList = get_params(obj)
	% Returns the used parameters.
	%
	% defaultParams = core_pipeline().get_params();
	%
		paramList = struct_to_list(obj.usedParams);
	end

	end

	methods (Access = private)

	function obj = train_processors(obj, trainData, varargin )
	% Train the processors involved in this pipeline. varargin
	% must contain the cell array definition of the processor list.

		% Treat all extractor definitions as lists of cell arrays
%		if(~all(cellfun(@iscell,varargin)))
%			varargin = {varargin};
%		end

		obj.processorList = cell(1,length(varargin));

		for i=1:length(varargin)
			
			assert(isfunlist(varargin{i}));
			
			[procFun,procParams] = split_funlist(varargin{i});

			%%%%%

			usedProcessor = procFun();	% construct
			[usedProcessor, XFeatures] = usedProcessor.train( trainData, procParams{:} );

			if(i < length(varargin))
				% there is a next stage, prepare the data for it. Dont bother
				% doing it for the last stage as the data wont be used.

				if(isempty(XFeatures))
					XFeatures = obj.run_processors(trainData, usedProcessor);
				end

				% The next extractor stage will always work with data from the previous one
				if(isstruct(XFeatures))
					trainData = XFeatures;
				else
					trainData.X = XFeatures;
				end
			end

			obj.processorList{i} = usedProcessor;
		end

	end

	function feats = run_processors(obj, dataset, customProcessorList)
	% Running a list of processors sequentially on the data.
	% Each processor is specified as a struct in customProcessorList cell array. Here
	% we use array from an argument to be able to run single processors
	% when needed.
		beStrict = false;

		% Treat all processorLists as lists of cell arrays
		if(~iscell(customProcessorList))
			customProcessorList = {customProcessorList};
		end

		for i=1:length(customProcessorList)

			feats = customProcessorList{i}.process(dataset);

			% n.b. Ideally the feature extractors *should* produce correct amount of vectors,
			% but we dont test the feature matrix size here as we dont want to
			% police what the pipeline does internally. What is demanded is that
			% the final dimensions are correct; these are tested in the caller
			if(isstruct(feats))
				dataset = feats;
			else
				assert( ~beStrict || ((size(feats,1) == dataset.numTrials) || (size(feats,1) == size(dataset.X,1))), ...
								   'Feature extractor returned vector count doesnt match sample or trial count');

				dataset.X = feats;
			end
		end

	end

	function dataset = augment_dataset(obj, dataset)
	% adds fields to the dataset which tells which classes each sample belongs to (sampleLabels)
	% and which trials each sample belongs to (trialLabels). Assumes trials do not overlap.
	%
		% find out which samples belong to which trials
		trialIds = zeros(dataset.numSamples,1);
		sampleLabels = zeros(dataset.numSamples,1);
		trialLabels = [];
		numTrials = 1;
		for i=1:length(dataset.events)
			matches = ismember(obj.usedParams.classEvents,dataset.events(i).type);
			w = find(matches);
			if(~isempty(w))
				assert(length(w)==1);
				startIdx = dataset.events(i).latency;
				stopIdx = dataset.events(i).latency+dataset.events(i).duration;
				assert(all(trialIds(startIdx:stopIdx)==0));
				trialIds(startIdx:stopIdx) = numTrials;
				sampleLabels(startIdx:stopIdx) = w;
				trialLabels = [trialLabels;w];
				numTrials = numTrials+1;
			end
			
		end
		assert(all(unique(trialIds)==(0:numTrials-1)'));
		
		dataset.trialIds = trialIds;
		dataset.sampleLabels = sampleLabels;
		dataset.trialLabels = trialLabels;
		dataset.numTrials = numTrials-1;
		dataset.numClasses = length(obj.usedParams.classEvents);
	end
	
	end
	end

