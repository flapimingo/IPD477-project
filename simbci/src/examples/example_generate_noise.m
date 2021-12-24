%
% Shows how to generate random noise with the conventions of the platform
%
clear;

% Assume we had 256 electrodes and wanted 60 seconds of Gaussian surface
% noise at 512hz sampling rate. We can do this in 'low-level' matlab, 
% but the resulting dataset will miss a lot of fields: event tags, electrode
% positions, sampling frequency, ... (unless inserted manually)

dataset1=[];
dataset1.X = randn(512*60,256);

% Alternatively, we can use the wrapper of the platform. This does not 
% bring any additional value.

dataset2=[];
dataset2.X = noise_gaussian([512*60 256]);

% Compared to the simplicity of this particular goal, using the high-level functions 
% has clear specification overhead but the dataset will have information about the 
% used parameters.

% We need a head model; the number of electrodes etc is figured out from this
default_head;

% We need to specify the duration of the recording (timeline)
timelineParams = { 'samplingFreq', 512, 'eventList', { ...
	  	{'when', {@when_empty, 'lengthSecs', 60} }} ...
};

% We need to specify what happens during the recording
effectParams = { ...		
	  {'SNR', 1.0, 'name', 'noise', 'triggeredBy', 'always', ...
		'what', @noise_gaussian, ...
		'where', @where_whole_surface} ...
};

% Finally, construct the generator and generate the data
generator = core_data_generator('headParams',headParams,'timelineParams',timelineParams,'effectParams',effectParams);
dataset3 = generator.generate_dataset();

% dataset.X will now contain the random noise

