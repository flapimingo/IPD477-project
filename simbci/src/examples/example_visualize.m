%
% Example how to visualize data generation and a pipeline
%
clear;
close all;

% Misc
set(0,'DefaultFigureColormap',feval('inferno'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Generating part
%
%

% Parameters controlling the generating head
default_head;

% Generative parameters
default_gen_motor_imagery;

% Assemble all together
generateParamsTrain = {'id','train', ...
	'headParams', headParams, ...
	'timelineParams', timelineParams, ...
	'effectParams',effectParams, ...
	'keepVolumeData',false,  ...
	'visualize', true ...
};

% Generate a dataset using the parameters
trainData = core_data_generator(generateParamsTrain{:}).generate_dataset();
% dump the figures related to data generation to ../../pics
save_figures('visuexample-01-forward-'); close all;

% None of this is needed anymore
clear generateParamsTrain noiseParams activityParams timelineParams;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Signal processing part
%
%

% Specification of classification pipeline to train. 
% Note how @proc_view calls have been peppered into the pipeline to show the
% data at different stages; these have no effect on the signal processing itself
pipeline = {'name','wmn-cincotti-modular', 'visualize', true, ...
	'classEvents', classEvents, ...
	'processors', { ...          % should be equivalent to wmn-cincotti in accuracy
  {@proc_view, 'method', 'plot', 'channelSet',1:9,'title', 'observed data (9 first chns)'}, ...
  {@proc_view, 'method', 'corrcoef', 'title', 'Observed correlations)'}, ...  
  {@proc_inverse_transform, 'visualize', true, ...
 		 'forward', {@core_head, headParams{:}}, ... % note we use the generating head model; this is optimistic!
		 'inverse',@wmn_inverse, ...
         'ROISelection', {@roi_heuristic, 'where', {@where_heuristic, 'position','leftAndRight', 'howMany', 2}, ...
		              'ROIDelta', {[0,0,0],[0,0,0]}}}, ...	% add 3D perturbation to ROI positions?
  {@proc_view, 'method', 'image', 'title', 'Inverse data'}, ...		 
  {@proc_spectrogram_features}, ...
  {@proc_view, 'method', 'image', 'title', 'Spectrogram features'}, ...  
  {@proc_correlation_selector}, ...	  
  {@proc_view, 'method', 'image', 'title', 'Selected features'}, ...  
  {@proc_interpolate_data}, ...			% used to compensate squeezing effect of spectrogram features
  {@proc_lda}, ...
  {@proc_view, 'method', 'image', 'normalizeDirection', 2, 'title', 'Raw LDA predictions'}, ...
  {@proc_identity} ... % the last process() is never called during train (as the data is normally unused), place identity here to get the previous step
  } ...
};

pipelineTrained = core_pipeline(pipeline{:}).train(trainData);

% dump the figures related to the signal processing to ../../pics
save_figures('visuexample-02-backward-'); close all;

