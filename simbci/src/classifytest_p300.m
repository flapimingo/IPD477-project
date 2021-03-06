%
% Toy P300 example
%
clear;
close all;

% setup_paths;

% Misc
set(0,'DefaultFigureColormap',feval('inferno'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

simulationParams = {'numIterations',10,'saveFigures',false,'id','p300','useCache',false};

% Parameters controlling the generating head
default_head;

classEvents = {'P300','noP300'};

% Parameters controlling experiment timeline generation:  when events happen
% Here positive class is much less likely than negative class (20% vs 80%
timelineParams = { 'samplingFreq', 200, 'eventList', { ...
	  	{'when', {@when_trials, 'events',classEvents, ...
		    'numTrials',50, 'classWeights',[0.2 0.8], ... 
			'trialLengthMs',1000, 'restLengthMs', 100, ...
			'trialOrder', 'random', 'includeRest', true}}, ...	
		{'when', {@when_random, 'events',{'eyeblink'},'eventFreq',0.1}}, ...
		{'when', {@when_random, 'events',{'eyemove'},'eventFreq',0.2,'randomMaxDurationMs',2000}}, ...		
		{'when', {@when_always, 'events',{'noise'}}} ...
	} ...
};

% Defines the activity created in the cortical volume thats to be classified
% @FIXME real P300 is unlikely to originate from a single dipolar source in occipital.
effectParams = { ...
	  {'SNR',1.0, 'name', 'signal', 'triggeredBy', classEvents{1}, ...
			'where', {@where_heuristic, 'position','occipital','howMany',1}, ...
			'what',   @gen_p300}, ...
	  {'SNR',0.1, 'name', 'eyeblinks', 'triggeredBy', 'eyeblink', ...
  			'where', {@where_heuristic, 'position','eyes'}, ...
			'what',   @noise_eyeblinks}, ...	 
	  {'SNR',0.1, 'name', 'eyemoves', 'triggeredBy', 'eyemove', ...
	    	'where', {@where_heuristic, 'position','eyes'}, ...
			'what',   @noise_eyemovement}, ...
	  {'SNR',0.001, 'name', 'noise', 'triggeredBy', 'noise', ... 
			'where',  @where_whole_volume, ... % example of a convenience function that doesn't need params
			'what',   @noise_pink} ...
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
generateParamsTest = set_parameter_in_context(generateParamsTest, 'events',classEvents, 'numTrials', 100);

% Specification of classification pipelines to be tested.
allPipelines = { ...
	{'name','erp-lda', 'classEvents', classEvents, 'processors', { ...
	  {@proc_erp_template}, ...
	  {@proc_normalize}, ...
	  {@proc_lda} } } ...
};

% These will no longer have effect, clear them
clear headParams timelineParams noiseParams;

% Construct the simulator and run
simulator = core_bci_simulator(simulationParams{:}, 'allPipelines',allPipelines, ...
	'generateParamsTrain', generateParamsTrain, 'generateParamsTest', generateParamsTest);
simulator = simulator.run_experiment();

% summary = simulator.summarize_results();
% simulator.print_summary(summary);



