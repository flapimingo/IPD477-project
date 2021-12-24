%
% Pipeline setup inspired by
% 
% Edelman & He, "EEG Source Imaging Enhances the Decoding of Complex Right-Hand Motor Imagery Tasks", 2016.
%
%

if(~exist('edelmanVisualize','var'))
	edelmanVisualize = false;
end

if(~exist('allPipelines','var'))
	allPipelines={};
end

% Note that TFR is used twice in different contexts
tfrParams = {'freqLow', 8, 'freqHigh', 13, ...
             'freqStep', 0.5, ...
			 'FWHM', 3, ...
			 'fc', 10, ...
			 'visualize', edelmanVisualize};
		
allPipelines = { allPipelines{:}, ...
	{'name','edelman-he', 'classEvents', classEvents, 'processors', ...
	  { ...
		  {@proc_bandpass_filter, 'freqLow',2,'freqHigh',30}, ...
		  {@proc_icaroi, 'forward', {@core_head, 'filename','sabre:/models/leadfield-sphere.mat','centerAndScale',true}, ... 
						 'icaParams', {'verbose','off', 'pcaDims',8}, ...
						 'downsampleFreq', 100, ...
						 'tfrParams', tfrParams, ...   
						 'keepDims',   4, ...
						 'activationThreshold', 0.75, ...
						 'visualize', edelmanVisualize}, ...
		  {@proc_tfr, tfrParams{:}}, ...
		  {@proc_md_selector, 'featsPerClass' 3, 'visualize', edelmanVisualize}, ...
		  {@proc_md_classifier, 'featsPerClass', 3, 'visualize',edelmanVisualize}
	  } ...
  } ...
};

% currently these parameters are not yet implemented
									   % 'TFRFeatsTimeDuration', 250e-3, ...
									   % 'TFRFeatsFreqBin', 2, ...
		   