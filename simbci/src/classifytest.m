%
% Motor Imagery classification test. See README.TXT
%
clear;
close all;

% setup_paths;

% Misc
set(0,'DefaultFigureColormap',feval('inferno'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Parameters controlling the simulation
simulationParams = {'numIterations',5,'saveFigures',true,'id','motorimagery','useCache',false};

% Setup the generating head
default_head;

% Setup signal parameters to generate 2 class motor imagery
default_gen_motor_imagery;

% Assemble all together; these come from the default scripts
generateParamsTrain = {'id','train', ...
	'headParams', headParams, ...
	'timelineParams', timelineParams, ...
	'effectParams', effectParams, ...
	'keepVolumeData',false,  ...
	'visualize', false ...
};

% Add CSP/Bandpower pipeline
default_pipeline_csp_bandpower;

% Construct the simulator and run. We use same parameters in both train and test.
simulator = core_bci_simulator( ...
	simulationParams{:}, ...
	'generateParamsTrain', generateParamsTrain, ...
	'generateParamsTest', generateParamsTrain, ... 
	'allPipelines', allPipelines);
simulator = simulator.run_experiment();

% summary = simulator.summarize_results();
% simulator.print_summary(summary);

