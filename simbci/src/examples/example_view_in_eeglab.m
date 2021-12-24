
%
% Illustrates how to export and view generated data in EEGLAB.
%
% Note that here we do not use a head model, all data is generated on the surface.
%

clear;

%%%% load eeglab first
% addpath('E:/jl/matlab/packages/eeglab13_6_5b/'); eeglab;

% Parameters controlling experiment timeline generation:  when events happen
timelineParams = { 'samplingFreq', 512, 'eventList', { ...
	  	{'when', {@when_trials, 'events',{'pink','gauss'}, ...
		    'numTrials',16, 'burninMs', 0, ...
			'trialOrder', 'roundrobin', 'includeRest', false}}
		} ...
};
		
% Alternate pink and gaussian noise with a strong 50hz mains power on top
effectParams = { ...		
	  {'SNR', 1.0, 'name', 'noise', 'triggeredBy', 'pink', ...
		'what',  @noise_pink, ...
		'where', {@where_heuristic, 'position','surface'}}, ...
	  {'SNR', 1.0, 'name', 'noise', 'triggeredBy', 'gauss', ...
		'what', @noise_gaussian, ...
		'where', {@where_heuristic, 'position','surface'}}, ...		
	  {'SNR', 0.01, 'name', 'noise', 'triggeredBy', 'always', ...
		'what', {@noise_frequency_spike, 'frequencyHz',50}, ...
		'where', {@where_heuristic, 'position','surface'}} ...			
		...		
};

% Assemble all together
generateParams = {'id','noise-example', ...
	'timelineParams', timelineParams, ...
	'effectParams',effectParams
};

% generate the data
dataset = core_data_generator(generateParams{:}).generate_dataset();

% Convert it to EEGLAB format
datasetEEG = dataset_to_eeglab(dataset);

% EEGLAB: Get a subset of channels for EEGLAB visualization clarity
datasetEEG = pop_select(datasetEEG, 'channel', 1:32);

% EEGLAB: Visualize; will be dominated by mains noise at 50hz
pop_eegplot(datasetEEG,1,0,0);
waitfor(gcf);

%% EEGLAB: filter the data to a frequency band of interest, remove power noise as a side effect
datasetEEG2 = pop_eegfiltnew(datasetEEG, 2, 40);
%% View again, will look more like EEG
pop_eegplot(datasetEEG2,1,0,0);

% EEGLAB: Save to file
% pop_saveset(datasetEEG, 'filename','test-set.set','savemode','twofiles');


