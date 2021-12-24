
clear; close all;

% run('../setup_paths.m');

% Tests generating different types of noise on top of each other, allows
% to check that the generators are working.

% Params related to the physical model used to generate the data
headParams = {
	'filename', 'sabre:/models/leadfield-sphere.mat', ...
	'centerAndScale', true};

% Parameters controlling experiment timeline: what happens and when
timelineParams = { 'samplingFreq',200, ...
	'eventList', { ...
	  	{'when', @when_trials, 'whenParams', {'events',{'left','right'}, ...
		    'numTrials',10, ... 
			'trialLengthMs',4000, 'restLengthMs', 2000, ...
			'trialOrder', 'random', 'includeRest', true}}, ...	
		{'when', @when_random, 'whenParams', {'events',{'eyeblink'},'eventFreq',0.2}}, ...
		{'when', @when_random, 'whenParams', {'events',{'eyemove'},'eventFreq',0.1,'randomMaxDurationMs',2000}}, ...
		{'when', @when_always, 'whenParams', {'events',{'noise'}}} ...
	} ...
};
			
effectParams = { ...	
	  {'SNR', 1.0, 'name', 'signalLeft', 'triggeredBy', 'left', ...
		'what', @gen_desync, 'whatParams', {'centerHz',12,'widthHz',1,'reduction',0.9}, ...
		'where', @where_heuristic, 'whereParams', {'position','rightMC'}}, ...	
	  {'SNR', 1.0, 'name', 'signalRight', 'triggeredBy', 'right', ...
		'what', @gen_desync, 'whatParams', {'centerHz',12,'widthHz',1,'reduction',0.9}, ...
		'where', @where_heuristic, 'whereParams', {'position','leftMC'}}, ...		
	  {'SNR', 0.5, 'name', 'blinks', 'triggeredBy', 'eyeblink', ...
		'what', @noise_eyeblinks, ...
		'where', @where_heuristic, 'whereParams', {'position','eyes'}}, ...
	  {'SNR', 0.5, 'name', 'eyemove', 'triggeredBy', 'eyemove', ...
		'what', @noise_eyemovement, ...
		'where', @where_heuristic, 'whereParams', {'position','eyes'}}, ...		
	  {'SNR', 0.5, 'name', 'noiseSpectral', 'triggeredBy', 'noise', ...
		'what', @noise_spectrally_colored, 'whatParams', {'subType','fake', 'strength', [1.0 0.5, 0.3]}, ...
		'where', @where_heuristic, 'whereParams', {'position','surface'}}, ...		
	  {'SNR', 0.5, 'name', 'noiseGauss', 'triggeredBy', 'noise', ...
		'what', @noise_gaussian, ...
		'where', @where_heuristic, 'whereParams', {'position','surface'}}, ...
	  {'SNR', 0.5, 'name', 'noisePink', 'triggeredBy', 'noise', ...
		'what', @noise_pink, ...
		'where', @where_heuristic, 'whereParams', {'position','surface'}}, ...		
	  {'SNR', 0.5, 'name', 'noiseLogunif', 'triggeredBy', 'noise', ...
		'what', @noise_logunif, ...
		'where', @where_heuristic, 'whereParams', {'position','surface'}} ...				
};

% generate a very specific dataset using parameters from above
generator = core_data_generator('id', 'myDataset', ...
		'headParams', headParams, ...
		'timelineParams', timelineParams,...
	    'effectParams', effectParams );
dataset= generator.generate_dataset();

figure();
plot(dataset.X(:,10));
