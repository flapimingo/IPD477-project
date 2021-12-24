
classdef core_bci_simulator
% CLASS_BCI_SIMULATOR Runs simulated BCI experiments
%

	properties
		usedParams          % Parameters used in the experiment
		isCompleted         % Did all the runs complete successfully?
		results             % All the collected results of the experiment
		resultFileName      % The file where results were saved to, if save was requested

		expandedParamsTrain % list of train set generation after all parameters expanded
		expandedParamsTest  % list of test set generation after all parameters expanded
		expandedPipelines   % list of pipelines after all parameters expanded
	end

	methods

	function obj = core_bci_simulator(varargin)
	% Default constructor
	%
	% 'generateParamsTrain' specifies the mechanisms for generating the train data
	% 'generateParamsTest' specifies the mechanisms for generating the test data
	% 'allPipelines' specifies the pipelines attempting to predict the brain states
	%
	% In a sense, the first two specify techniques for 'forward modelling'
	% (generating measurements from simulated sources) and the last, techniques
	% for 'inverse processing' (going from EEG measurements to predicting something
	% about the sources).
	%
	% allPipelies and the generative params can contain parameters stated with
	% 'loop_these([val1,val2,...])' specifications. These are expanded so that all
	% different possible parameter combinations will each result in a specific
	% generator or pipeline. Then, the simulations are run with each such
	% component.
	%

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'id',                     'anon',      @ischar);
		addParameter(p, 'allPipelines',                   {},  @iscell);
		addParameter(p, 'generateParamsTrain',            {},  @iscell);
		addParameter(p, 'generateParamsTest',             {},  @iscell);
		addParameter(p, 'numIterations',              2,   @isint);
		addParameter(p, 'printSummary',            true,   @islogical);
		addParameter(p, 'saveFigures',            false,   @islogical);
		addParameter(p, 'saveResults',            false,   @islogical);
		addParameter(p, 'closeFigures',           false,   @islogical);		% close figures on exit
		addParameter(p, 'doResume',               false,   @islogical);
		addParameter(p, 'useCache',                true,   @islogical);
		addParameter(p, 'debugIfAccuracyBelow',       0,   @isnumeric);
		addParameter(p, 'visualize',              false,   @islogical);
		addParameter(p, 'randomSeed',          'shuffle');		% param that rng() can accept, type not checked.
		addParameter(p, 'verbose',                false,   @islogical);

		p.parse(varargin{:});
		obj.usedParams = p.Results;

		if(isempty(obj.usedParams.generateParamsTest))
			% Use same params as for training
			obj.usedParams.generateParamsTest = obj.usedParams.generateParamsTrain;
		end

		% Expand all parameters
		obj.expandedParamsTrain = expand_parameters(obj.usedParams.generateParamsTrain{:});
		obj.expandedParamsTest = expand_parameters(obj.usedParams.generateParamsTest{:});

		% @todo allow testing different train/test combos in the future. Now they're assumed to have
		% corresponding pairs.
		assert(length(obj.expandedParamsTrain) == length(obj.expandedParamsTest), ...
			 ['The train and test parameter lists should have the same amount of entries.' ...
			  ' To vary one parameter in train and to keep it fixed in test, use loop_these() with identical values. E.g. loop_these(1:3) in train with loop_these([5,5,5]) in test.']);

		% each pipeline needs to be expanded separately as they're independent from each other
		expandedPipelines={};
		for i=1:length(obj.usedParams.allPipelines)
			tmp = obj.usedParams.allPipelines{i};
			tmpRes = expand_parameters(tmp{:});
			expandedPipelines = [expandedPipelines;tmpRes];
		end

		obj.expandedPipelines = expandedPipelines;

		obj.isCompleted = false;

		% Preallocate the empty results structure
		obj.results = cell(length(obj.expandedParamsTrain)*length(obj.expandedPipelines),4);
		for i=1:size(obj.results,1)
			obj.results{i,4} = zeros(obj.usedParams.numIterations,7);
		end

		% can we use disk cache?
		if(obj.usedParams.useCache && ~usejava('jvm'))
			fprintf(1,'Warning: Cannot use disk cache without jvm, disabling.\n');
			obj.usedParams.useCache = false;
		end
	end

	function [ obj, results, resultFileName ] = run_experiment( obj )
	% Runs one or more BCI simulations.
	%
	% Output 'results' contains the results of the experiments.
	% 'resultFileName' is the name of the file results were saved to, if save requested.
	%
	% Intuitively, each row of 'results' can be though of as a row in a relational
	% database that specifies the experiment conditions and the experiment result.
	%
	% Technically, if H data generators and K pipelines are expanded,
	% the 'results' is structured as follows,
	%
	% {trainGeneration1Params} {testGeneration1Params} {pipeline1Params} {resultMatrix}
	% {trainGeneration1Params} {testGeneration1Params} {pipeline2Params} {resultMatrix}
	% ...
	% {trainGeneration1Params} {testGeneration1Params} {pipelineKParams} {resultMatrix}
	% ...
	% {trainGeneration2Params} {testGeneration2Params} {pipeline1Params} {resultMatrix}
	% {trainGeneration2Params} {testGeneration2Params} {pipeline2Params} {resultMatrix}
	% ...
	% {trainGeneration2Params} {testGeneration2Params} {pipelineKParams} {resultMatrix}
	% ...
	% {trainGenerationHParams} {testGenerationHParams} {pipelineKParams} {resultMatrix}
	%
	% resultMatrix has the following components, one row per iteration,
	%
	%  [ trainAccuracy, testAccuracy,  estimationTime, evaluationTime, generationTime, trainData.numTrials, testData.numTrials ;
	%    trainAccuracy, testAccuracy,  estimationTime, evaluationTime, generationTime, trainData.numTrials, testData.numTrials, ...
	%     ...
	%   ];
	%
	%
	%
		obj.isCompleted = false;

		if(obj.usedParams.doResume)
			fprintf(1,'Attempting to resume previous experiment...\n');
			prefix = expand_path(sprintf('sabre:/cache/%s/incomplete/', obj.usedParams.id));
			d = dir(prefix);
			if(~isempty(d))
				fn = sprintf('%s/%s',prefix, d(end).name);
				fprintf(1,'Loading state from %s\n', fn);
				obj = obj.load_state(fn);
			end
		end

		fprintf(1,'Starting experiments: %d generators, %d pipelines, %d iterations = %d total ...\n', ...
				length(obj.expandedParamsTrain),length(obj.expandedPipelines),obj.usedParams.numIterations, ...
				length(obj.expandedParamsTrain)*length(obj.expandedPipelines)*obj.usedParams.numIterations);

		% Note: Should normally be 'shuffle' to make sure that if we resume an experiment,
		% starting from step t won't get the randomness at t that we already used in step 1.
		rng(obj.usedParams.randomSeed);

		% Create the directories needed, the latter is used even if the hash cache is not used
		cacheDir = expand_path(sprintf('sabre:cache/%s', obj.usedParams.id));
		if(~exist(cacheDir, 'dir'))
			mkdir(cacheDir);
		end
		incompleteDir = expand_path(sprintf('sabre:cache/%s/incomplete', obj.usedParams.id));
		if(~exist(incompleteDir,'dir'))
			mkdir(incompleteDir);
		end

		timeLastSave = cputime();

		% Loop over each different parameter set to generate the data
		for generatorIndex=1:length(obj.expandedParamsTrain)

			fprintf('Generator %02d / %02d ...\n', generatorIndex, length(obj.expandedParamsTrain));

			% Do the requested amount of repetitions to get a smoother accuracy estimate.
			for iterationIndex=1:obj.usedParams.numIterations
				obj = obj.run_iteration(generatorIndex, iterationIndex);
			end

			if(obj.usedParams.saveFigures)
				save_figures(sprintf('debug-%03d-',generatorIndex));
			end
			if(obj.usedParams.closeFigures)
				close all;
			end
			
			if(obj.usedParams.saveResults)
				timeNow = cputime();
				if(timeNow - timeLastSave > 10*60 && generatorIndex < length(obj.expandedParamsTrain))
					% its been over 10 minutes since last save
					obj = obj.save_state(false);
					timeLastSave = timeNow;
				end
			end
		end

		obj.isCompleted = true;

		if(obj.usedParams.saveResults)
			obj = obj.save_state(false);				% also save the last 'incomplete' result for workflows that use doResume
			obj = obj.save_state(true);
		else
			obj.resultFileName = '(save not requested)';
		end

		results = obj.results;
		resultFileName = obj.resultFileName;

		if(obj.usedParams.printSummary)
			summary = obj.get_summary();
			obj.print_summary(summary);
		end
	end

	function paramList = get_params(obj)
	% Returns the used parameters as a list.
	%
	% defaultParams = core_bci_simulator().get_params();
	%
		paramList = struct_to_list(obj.usedParams);
	end


	function summary = get_summary(obj)
	% Returns a summary of the simulation results
	%
	% The output will be a cell array of the following structure,
	% {pipeline1id} {pipeline1results}
	% {pipeline2id} {pipeline2results}
	% ...
	%
	% Each pipelineXresults will contain the results of all the tested generator parameters
	%
		assert(obj.isCompleted, 'Summary only available after successful finish');

		% Figure out which parameters were specified as @loop_these
		tmpParamsTrain = expand_parameters_only(obj.usedParams.generateParamsTrain{:});
		% expandedParamsTest = expand_parameters_only(obj.usedParams.generateParamsTest{:});
		unexpandedPipelines = obj.usedParams.allPipelines;
		tmpParamsPipe = expand_parameters_only(unexpandedPipelines{:});		

		% pipelines need to be expanded separately as they're independent
		allPipelineIds={};
		for i=1:length(unexpandedPipelines)
			tmp = unexpandedPipelines{i};
			tmpRes = expand_parameters(tmp{:});
			for j=1:size(tmpRes,1)
				thisRes = tmpRes{j};
				name = get_parameter(thisRes, 'name');
				if(isempty(tmpParamsPipe))
					tmpPair = { name, j, {} } ;
				else
					tmpPair = { name, j, tmpParamsPipe{j}{:} } ;
				end
				padded = cat(1, allPipelineIds, tmpPair);
				allPipelineIds = padded;
			end
		end

		if(isempty(tmpParamsTrain))
			totalParamsLooped = 1;	% how many params were expanded (no expansions = 1 constant parameter)
			numGenerators = 1;
			tmpParamsTrain = {{'default'}};
		else
			totalParamsLooped = size(tmpParamsTrain{1},2);
			numGenerators = size(tmpParamsTrain,1);
		end
		totalMethodsLooped = size(allPipelineIds,1);

		summary = cell(totalMethodsLooped,2);

		% loop over methods
		for m=1:totalMethodsLooped
			resultsForMethod = obj.results(m:totalMethodsLooped:end,:);

			assert(size(resultsForMethod,1) == numGenerators);

			simplifiedResults = cell(numGenerators,  totalParamsLooped+2);

			for j=1:numGenerators
				thisRes = resultsForMethod{j,end};
	%			thisResMean = mean(thisRes,1);

				tmp = cat(2,tmpParamsTrain{j}, 'result', thisRes);
				simplifiedResults(j,:) = tmp;
			end

			summary(m,1) = { {allPipelineIds{m,:}} } ;
			summary(m,2) = { simplifiedResults } ;

		end

	end

	function obj = save_state(obj, isFinal)
	% SAVE_STATE saves the state of the simulator.
	%
	% postfix : an additional string appended to the constructed filename
	%
	% Changes the filename stored in the object as a side effect
		datStr = datestr(datetime('now'),30);	% filename needs to be windows compatible, so 30
		datStr = regexprep(datStr,' ','-');
		if(isFinal)
			obj.resultFileName = expand_path(sprintf('sabre:/experiments/results/simulation_results-%s-%s-final.mat', ...
							  obj.usedParams.id, datStr));
		else
			obj.resultFileName = expand_path(sprintf('sabre:/cache/%s/incomplete/simulation_results-%s-incomplete.mat', ...
							  obj.usedParams.id, datStr));
		end

		fprintf(1, 'Saving %s...\n', obj.resultFileName);
		save(obj.resultFileName, 'obj');
	end

	function obj = load_state(~,fn)
	% LOAD_STATE loads a previously saved state
		obj = load(fn);
		obj = obj.obj;
	end

	% Methods
	end

	methods(Static)

	function print_summary(summary)
	% Elementary printing of a summary of results.
	%
	% The input can be obtained from obj.get_summary().
	%
		for k=1:size(summary{1,2},1)
			fprintf('Generative parameter set %d/%d:\n', k, size(summary{1,2},1));

			% Print generation times; note that if the generative
			% pipeline has very different parameters per simulation,
			% this pools them all up
			fprintf(1, 'Time consumption\n');
			generationTimeTotal = 0; trainTrialsTotal = 0; testTrialsTotal = 0;
			estimationTimeTotal = 0; evaluationTimeTotal = 0;
			for i=1:size(summary,1)
				results = summary{i,2}{k,end};

				estimationTime = mean(results(:,3));
				evaluationTime = mean(results(:,4));
				generationTime = mean(results(:,5));
				trainTrials = mean(results(:,6));
				testTrials = mean(results(:,7));

				fprintf(1, '  %02d %s - Estimation %.2fs (%.2fs/trial), testing %.2fs (%.2fs/trial), data generation %.2fs (%.2fs/trial)\n', ...
					i,  char(summary{i,1}{1}), ...
					estimationTime, estimationTime/trainTrials, ...
					evaluationTime, evaluationTime/testTrials, ...
					generationTime, generationTime/(trainTrials + testTrials) ...
				);

				generationTimeTotal = generationTimeTotal + generationTime;
				estimationTimeTotal = estimationTimeTotal + estimationTime;
				evaluationTimeTotal = evaluationTimeTotal + evaluationTime;
				trainTrialsTotal = trainTrialsTotal + trainTrials;
				testTrialsTotal = testTrialsTotal + testTrials;
			end
			generationTimeTotal = generationTimeTotal / size(summary,1); % all pipelines use the same datasets generated only once

			fprintf(1, '  Totals: Estimation %.2fs (%.2fs/trial), testing %.2fs (%.2fs/trial), data generation %.2fs (%.2fs/trial) \n', ...
				estimationTimeTotal, estimationTimeTotal/trainTrialsTotal, ...
				evaluationTimeTotal, evaluationTimeTotal/testTrialsTotal, ...
				generationTimeTotal, generationTimeTotal/(trainTrialsTotal + testTrialsTotal)  ...
			);

			% print training set accuracies
			fprintf(1,'Training accuracies\n');
			for i=1:size(summary,1)
				results = summary{i,2}{k,end};

				% The means are over the iterations
				trainingAcc = results(:,1);

				fprintf(1, '  %02d %s - Mean %.2f std %.2f min %.2f\n', ...
					i,  char(summary{i,1}{1}), ...
					mean(trainingAcc), std(trainingAcc), min(trainingAcc));
			end

			% print testing set accuracies
			fprintf(1,'Testing accuracies\n');
			for i=1:size(summary,1)
				results = summary{i,2}{k,end};

				% The means are over the iterations
				trainingAcc = results(:,2);

				fprintf(1, '  %02d %s - Mean %.2f std %.2f min %.2f\n', ...
					i,  char(summary{i,1}{1}), ...
					mean(trainingAcc), std(trainingAcc), min(trainingAcc));
			end
		end
	end

	function merged = merge_results( res1, res2 )
	% Merges results of two simulators
	%
	% Note that this function currently assumes that the key,value pairs in both of
	% the results are in the same order. Also, it is not that useful as the result
	% summary routine would require merging of the parameters as well, which is
	% not currently done.
	%
		if(isempty(res1))
			merged = res2;
			return;
		end
		if(isempty(res2))
			merged = res1;
			return;
		end

		% true, if the parameter spec of a line of results was matched in the other set
		matchedIn1 = zeros(size(res1,1),1);
		matchedIn2 = zeros(size(res2,1),1);

		merged = {};
		for i=1:size(res1,1)

			% see if any row in res2 matctes this row i of res1
			for j=1:size(res2,1)
				% Check that the trainGen,testGen and pipeline params are the same
				if(isequal(res1{i,1},res2{j,1}) ...
					&& isequal(res1{i,2},res2{j,2}) ...
					&& isequal(res1{i,3},res2{j,3}))
					% if yes, these are the same parameters, just merge the result matrixes
					merged = cat(1,merged,res1(i,:));
					merged{end,4} = [merged{end,4};res2{j,4}];

					matchedIn1(i) = true;
					matchedIn2(j) = true;
					break;
				end
			end
		end

		% matchedIn1
		% matchedIn2

		% append the rows that didn't have a match in the other set
		if(any(matchedIn1==0))
			merged = cat(1,merged,res1(~matchedIn1,:));
		end
		if(any(matchedIn2==0))
			merged = cat(1,merged,res2(~matchedIn2,:));
		end

	end


	% methods(Static)
	end

	methods(Access = private)

	function obj = run_iteration(obj, generatorIndex, iterationIndex)
	% Generates a pair of train and test sets and runs all pipelines on them
	%
	% Each iteration creates the following matrix per pipeline
	%
	%  [ trainAccuracy, testAccuracy,  estimationTime, evaluationTime, generationTime, trainData.numTrials, testData.numTrials];
	%
	%
	% n.b. All params should be already 'expanded', i.e. not contain any loop_these()
	% items. For using such in parameter lists, use 'run_experiment.m'.
	%
	%
		if(nargin<2)
			generatorIndex = 1;
		else
			assert(generatorIndex<=length(obj.expandedParamsTrain));
		end
		if(nargin<3)
			iterationIndex = 1;
		end

		paramsTrain = obj.expandedParamsTrain{generatorIndex};
		paramsTest = obj.expandedParamsTest{generatorIndex};
		allPipelines = obj.expandedPipelines;

		% Check first if we've already computed this result
		alreadyComputed = false;
		if(obj.usedParams.doResume)
			% Do we have the result in memory on resume?
			% Since we save results only after the whole iteration is complete,
			% its sufficient to test if there are results for the first pipeline.
			firstIdx = (generatorIndex-1)*length(allPipelines) + 1;

			% Test variable that is likely to be naturally > 0
			generatingTimeSpent = obj.results{firstIdx,4}(iterationIndex,5);
			if(generatingTimeSpent>0)
				if(obj.usedParams.verbose) fprintf(1,'Result in memory\n'); end
				alreadyComputed = true;
			end
		end
		
		% Do we have the result in disk cache?
		if(~alreadyComputed && obj.usedParams.useCache)
			hashKey = {paramsTrain,paramsTest,allPipelines,iterationIndex};
			serializedKey = hlp_cryptohash(hashKey);
			cacheFile = expand_path(sprintf('sabre:cache/%s/%s.mat', obj.usedParams.id, serializedKey));

			if(exist(cacheFile,'file'))
				cacheEntry = load(cacheFile);
				if(isequal(cacheEntry.hashKey,hashKey))
					% ok, there was no hash collision, the parameters seem to be the same
					resultChunk = cacheEntry.resultChunk;
					alreadyComputed = true;
					if(obj.usedParams.verbose) fprintf(1,'Result in disk cache\n'); end
				else
					fprintf(1,'Warning: Disk hash collision, recomputing...\n');
				end
			end
		end

		% Compute it?
		if(~alreadyComputed)
			resultChunk = zeros(length(allPipelines),7);

			fprintf(1, '  Iteration %02d / %02d ... Generating data...', iterationIndex, obj.usedParams.numIterations);

			tic;

			% Generate independent train and test sets
			trainData = core_data_generator(paramsTrain{:}).generate_dataset();
			testData = core_data_generator(paramsTest{:}).generate_dataset();

			generationTime = toc;

			fprintf(1,' done.\n    ');

			% Evaluate all pipelines with the generated sets
			for p = 1:length(allPipelines)
				pipelineParams = allPipelines{p};
				pipelineName = get_parameter(pipelineParams,'name');
				fprintf(1, '%d:%s ... ', p, pipelineName);

				% Train a classifying pipeline. All info needed to do classification must be stored in 'pipeline' by the function.
				tic;
				pipelineTrained = core_pipeline( pipelineParams{:} ).train(trainData);
				estimationTime = toc;

				% Classify train data. Mostly for debugging / overfit analysis purposes.
				tic;
				[trainPredictions,~,trainTrialLabels] = pipelineTrained.predict(trainData);
				trainAccuracy = mean(trainPredictions==trainTrialLabels);
				% @FIXME could also record variance here

				% Classify new data.
				[testPredictions,~,testTrialLabels] = pipelineTrained.predict(testData);
				testAccuracy = mean(testPredictions==testTrialLabels);
				evaluationTime = toc;

				if(testAccuracy<obj.usedParams.debugIfAccuracyBelow)
					fprintf(1,'Test accuracy is %f, debug ...	\n', testAccuracy);
					keyboard
				end

				thisRes = [ trainAccuracy, testAccuracy,  estimationTime, evaluationTime, generationTime, length(trainTrialLabels), length(testTrialLabels)];
				if(any(isnan(thisRes) | isinf(thisRes)))
					fn = sprintf('debug-%s.mat', obj.usedParams.id);
					save(fn);
					assert(false, sprintf('Pipeline results had NaNs or Inf. This is not supported and indicates a bug. Please debug generation and/or pipelines.\nState was saved to %s\n',fn));
				end

				resultChunk(p,:) = thisRes;

				% get a bit of memory back
				clear pipelineTrained trainPredictions testPredictions;
			end

			fprintf(1,'\n');
		end

		if(obj.usedParams.useCache && ~alreadyComputed)
			save(cacheFile,'resultChunk','hashKey');
		end

		% Finally store the results of this iteration
		for p = 1:length(allPipelines)
			pipelineParams = allPipelines{p};

			thisIdx = (generatorIndex-1)*length(allPipelines) + p;

			obj.results{thisIdx,1} = paramsTrain;
			obj.results{thisIdx,2} = paramsTest;
			obj.results{thisIdx,3} = pipelineParams;
			obj.results{thisIdx,4}(iterationIndex,:) = resultChunk(p,:);
		end
	end

	% // methods(Access=private)
	end

% Class
end

