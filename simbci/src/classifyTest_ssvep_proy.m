%
% Implementation of the experiment presented on
% "Poor performance in SSVEP BCIs: Are worse subjects just slower?"
%  doi.org/10.1109/EMBC.2012.6346803
%
clear;
close all;

setup_paths;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

simulationParams = {
    'id','ssvep',...
    'numIterations',50, ...
    'printSummary', true, ...
    'saveFigures', false, ...
    'useCache', false
};

% parameters controlling the generating head
default_head;

classEvents = {'up', 'right', 'down', 'left'};

%trialLength = [7000]; %Value in [ms]. 7000 initial value
trialLength = [7000, 8000, 9000, 10000];

% Parameters controlling experiment timeline generation: when events happen
timelineParams = { 'samplingFreq', 256, 'eventList', { ...
        {'when', {@when_trials, 'events', classEvents, 'numTrials', 20, ...
            'burninMs', 10000, 'trialLengthMs', loop_these(trialLength),...
            'restLengthMs', 3000, 'trialOrder', 'increasing',...
            'includeRest', true, 'visualize', false }}, ...
        {'when', {@when_random, 'events',{'eyeblink'},'eventFreq',0.1}},...
		{'when', {@when_random, 'events',{'eyemove'},'eventFreq',0.2,...
            'randomMaxDurationMs',2000}}, ...		
		{'when', {@when_always, 'events',{'noise'}}} ...
    } ...
};

% Parameters controlling the noise
% Defines the activity created in the cortical volume thats to be classified
effectParams = { ...
	  {'SNR',1.0,'name','signal', 'triggeredBy',classEvents{1}, ...
	    'where', {@where_heuristic, 'position','occipital', 'howMany', 1}, ...
		'what',  {@gen_ssvep, 'flickerHz',10}}, ...
	  {'SNR',1.0,'name','signal', 'triggeredBy',classEvents{2}, ...
	    'where', {@where_heuristic, 'position','occipital', 'howMany', 1}, ...
		'what',  {@gen_ssvep, 'flickerHz',11}}, ...
	  {'SNR',1.0,'name','signal', 'triggeredBy',classEvents{3}, ...
	    'where', {@where_heuristic, 'position','occipital', 'howMany', 1}, ...
		'what',  {@gen_ssvep, 'flickerHz',12}}, ... 
      {'SNR',1.0,'name','signal', 'triggeredBy',classEvents{4}, ...
	    'where', {@where_heuristic, 'position','occipital', 'howMany', 1}, ...
		'what',  {@gen_ssvep, 'flickerHz',13}}, ...	
	  {'SNR',0.1, 'name', 'eyeblinks', 'triggeredBy', 'eyeblink', ...
  		'where', {@where_heuristic, 'position','eyes'}, ...
		'what',  {@noise_eyeblinks}}, ...	 
	  {'SNR',0.1, 'name', 'eyemoves', 'triggeredBy', 'eyemove', ...
	  	'where', {@where_heuristic, 'position','eyes'}, ...
		'what',  {@noise_eyemovement}}, ...
	  {'SNR',0.05,'name','noise', 'triggeredBy', 'noise', ...
	    'where',  @where_whole_surface, ... 
		'what',  {@noise_spectrally_colored, 'subType','fake', 'strength', ... 
        [1.0 0.5, 0.3]}}...
};

% Assemble all together
generateParamsTrain = {'id','train', ...
	'headParams', headParams, ...
	'timelineParams', timelineParams, ...
	'effectParams', effectParams, ...
	'keepVolumeData',false,  ...
	'visualize', false ...
};

% Params used for generating test data. Usually should resemble train data generation,
% unless you want to test the effects of the two deviating.
generateParamsTest = generateParamsTrain;
generateParamsTest = set_parameter(generateParamsTest, 'id', 'test');
generateParamsTest = set_parameter_in_context(generateParamsTest, 'events',classEvents, 'numTrials', 1);

% Specification of classification pipelines to be tested.
allPipelines = { ...
	{'name','SSVEPBox sim', 'classEvents',classEvents,'processors', { ...
	    {@proc_. sp_bandpower, 'logFeats',false,'freqLow',0.5,...
            'freqHigh',30, 'dim', 2, 'tikhonov', 0.5, 'shrink', 0.5},...
        {@proc_lda},...
        }
    }
};

% These will no longer have effect, clear them
clear headParams;

% Construct the simulator and run
simulator = core_bci_simulator(simulationParams{:}, 'allPipelines',allPipelines, ...
	'generateParamsTrain', generateParamsTrain, 'generateParamsTest', generateParamsTest);
[simulator, results, ] = simulator.run_experiment();

summary = simulator.get_summary();
simulator.print_summary(summary);

%% Testing the EEG dataset generation
% re define trialLength value

datasetParams = {'id', 'generated EEG dataset', ...
    'timelineParams', timelineParams, ...
    'effectParams', effectParams, ...
    'keepVolumeData', false, ...
    'visualize', false};

dataset = core_data_generator(datasetParams{:}).generate_dataset();
visualize_dataset(dataset,'method','plot');

%% Working with results
resultMatrix = results(:,4);
minAcc = zeros(length(resultMatrix),1);
maxAcc = zeros(length(resultMatrix),1);
avgAcc = zeros(length(resultMatrix),1);

for i=1:length(resultMatrix)
    trialStats = resultMatrix(i,:);
    testAcc = trialStats{1}(:,2);
    minAcc(i) = min(testAcc);
    maxAcc(i) = max(testAcc);
    avgAcc(i) = mean(testAcc);
end

plot(trialLength, minAcc, '--v', trialLength, maxAcc, '--^', trialLength, avgAcc, '--d')
legend({'Minimum accuracy','Maximum accuracy', 'Mean accuracy'}, 'Location', 'northwest')
legend('boxoff')
xlabel('Trial length [ms]')
ylabel('Accuracy')
title('Accuracy by simulated trial lengths')
axis padded