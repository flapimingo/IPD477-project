%
% Example how to generate a motor imagery -like dataset resembling
% the one in the BCI Competition IV summary paper by Tangermann & al.
%
clear;
close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Setup the generating head
default_head;

% Setup the parameters
default_gen_motor_imagery;
		
% Assemble all together
generateParams = {'id','artificial set', ...
	'headParams', headParams, ...
	'timelineParams', timelineParams, ...
	'effectParams',effectParams, ...
	'keepVolumeData',false,  ...
	'visualize', false ...
};

dataset = core_data_generator(generateParams{:}).generate_dataset();

% Show some elementary visualizations
visualize_dataset(dataset,'method','image','title','Surface data');
visualize_dataset(dataset,'method','corrcoef');
visualize_dataset(dataset,'method','plot','channelSet',1:9);
visualize_dataset(dataset,'method','periodogram','channelSet',1:9);

