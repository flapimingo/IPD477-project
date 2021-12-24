
simBCI - Testbench for simulated EEG-like data & BCI classification
===================================================================

simBCI can generate train and test data in the cortical volume and project them 
to the surface. Further, it can estimate signal processing pipelines to discriminate 
between different brain states using the training data. The trained pipelines can
be evaluated with test data, and classification accuracies obtained. The main 
outputs of interest typically are the classification accuracy of each pipeline and 
the time it took. It is also possible to plug in visualizers to different stages
of the signal generation or processing to illustrate how the data changes.

The framework allows studying how changing the conditions either on the generative
side or the classifier pipeline side affects the accuracies. It can be used to 
better understand BCI signal processing algorithms and their interplay
with the properties of the data. Unlike with human experiments, the data
characteristics can be perfectly controlled in simulation.

The classification pipelines are composed of data processor modules, where
typically some feature extractors are followed by a classifier. Each module can be 
trained if it requires it. Examples of feature extractors are CSP and sLORETA. 
Examples of classifiers are LDA and 'threshold' (a fixed function). In the framework 
inverse models are conceptually seen as a certain kind of feature extractors. 

Getting started
---------------

Matlab>> cd src; setup_paths
Matlab>> classifytest

What it does, in stages (simplified)

0) Set parameters for data generation: the head model, a motor imagery generator
consisting of specific trial (timeline) structure, and signal and noise components
1) Set parameters for to get a CSP/Bandpower classification pipeline
2) Using these parameters, the call to BCI Simulator class will roughly carry 
out the following,

Iterate(
  3) Generate experiment timeline
  4) Trigger generators to react to the timeline events
  5) Map/mix the volume data to surface (with linear superposition model)
  6) Train classification pipeline given the surface EEG data
	  - Train first module of the pipeline, get its processed output
	  - Use the output to train the second module...
	  - ...
  7) Predict brain states for a separate test set with pipeline 
      - Run the first (possibly trained) module with raw data
	  - Run the second (possibly trained) module with the output of the previous step
	  - ...
  8) Compute accuracy by comparing the trial labels to pipeline outputs
)

The scripts in the folder 'examples/' may also be of interest.

Platform(s)
-----------
Tested on Matlab 2015b, Win10; likely also works with 2014b+Win7.

Requirements
------------
Some parts of the framework may rely on

Image Processing Toolbox (im2col, imresize)


Glossary & notation
-------------------

activity - some cortical property in the volume that should be classified
dataset - a structure that contains the surface signal and the associated timeline and labels for samples and trials
experiment - here usually the process of creating dataset, building DSP pipelines, and evaluating them together
generator - a component sampling artificial data
iteration - one repetition of simulation (i.e. generate and evaluate one train/test set pair using all pipelines)
leadfield - a forward transform (or head model) specifying signal mapping from volume to surface
noise - all other cortical or noncortical activity in the signal
surface - the scalp where EEG potentials can be measured with electrodes
processor - a component that transforms the signal in some manner, usually 'feature extractors' and 'classifiers'.
pipeline - a sequence of processors, usually ending up in a 'classifier' kind of processor
simulation - a loop where (random generate data + train model + test model) is repeated a requested number of times
SNR - signal to noise ratio
timeline - a description what happens and when in a BCI paradigm (e.g. 'think left, rest, think right'...). A sequence of trials.
trial - a time segment during which some specific activity is supposed to occur
volume - the 'brain', contains the sources of EEG signal generation; directly unobservable in real EEG; modelled by dipole distribution
volume conduction - biological transform from volume to surface that the leadfield models

A - forward model matrix [nElectrodes x nDipoles*3]
S - source data matrix (inside volume, [nSample x nDipoles])
X - measurement data matrix (surface, [nSample x nElectrodes]), also used for transformed samples in pipelines

electrodePos = [nElectrodes x 3]
sourcePos = [nDipoles x 3]

Feature vector matrices are assumed oriented as [exampleNumber x featureNumber].

I.e. X(1,:) is the first sample in a recording, feat(1,:) is the first feature vector. 
X(1:samplingFreq,:) is the first second of data recording.


Conventions
-----------

NOTE about the head model (leadfield) orientation: The various components
in the code ASSUME that the interpretation of x,y,z is as follows,

x : the dimension from 'left ear to right ear'  (left mastoid - right mastoid, [-,+])
y : the dimension from 'back of the head to nose' (inion - nasion) [-,+]
z : the dimension from 'bottom of the head to the top of the head'  (ventral - dorsal) [-,+]

If the model is oriented wrong, the results will be bad.


Directory hierarchy
-------------------

- cache/                 : results can be cached here
- contrib/               : third-party dependencies and contributions
- doc/                   : some scribblings
- models/                : head models (leadfields)
- pics/                  : scripts can spool some images here if requested
- src/classifiers/       : processor classes considered as classifiers
- src/config/            : convenience scripts to set up default parameters
- src/core/              : the main architecture
- src/examples/          : example scripts that show how to do some simple things
- src/extractors/        : processor classes considered as feature extractors, filters,  etc
- src/noise              : noise generator functions
- scr/tests/             : some ad-hoc tests
- src/utils/             : miscellaneous helper functions required by the framework
- src/visualizers/       : some display plugins
- src/what/              : noise and signal generators 
- src/when/              : timeline component generators
- src/where/             : functions to localize physiological landmarks of interest


Design & Components
-------------------
The idea of simBCI is to be modular and yet allow specification of all experiment 
parameters of interest from the main level study script.

- Signal processing plugins used in a pipeline are classes. They are expected 
  to have train() and process() member functions.
- Signal and noise generators and inverse transforms are normal functions 

The data generation and the classifier training are controlled by 
cell array parameter lists. All the parameters can be specified
by these lists. If a list lacks a parameter, it will be filled with
a default value. The different generators or processing plugins
are chained by specifying their function pointers or a sequence
of such with these parameter lists. These are perhaps best understood
by looking at the examples in 'src/config/'.

The framework tries to be agnostic about the actual computation or what the models
or parameters contain or mean, it just passes the results of the computations from one
component to another. 


Examples
---------
The easiest way to get intuition to the framework is to look at the following
entry points (main level scripts),

src/classifytest.m - An example running a set of pipelines on data generated in
a specific way. 

src/examples/*.m

  
Parameter list handling
-----------------------
A key component of the framework are nested parameter lists. A parameter
list specifies {key,value} pairs, where each value can be a sublist,
or a list of lists, recursively. Different data generation mechanisms
and signal processing pipelines are specified by these parameter lists 
in the main level script.

Example:

timelineParams = { 'samplingFreq', 200, 'eventList', { ...
	  	{'when', {@when_trials, 'events',{'rightMC','leftMC'}, ...
		    'numTrials',10, ... 
			'trialLengthMs',4000, 'restLengthMs', 2000, ...
			'trialOrder', 'random', 'includeRest', true}}, ...	
	} ...
};

effectParams = { ...	
	  {'SNR', 1.0, 'name', 'signalLeft', 'triggeredBy', 'left', ...
		'what',  {@gen_desync, 'centerHz',12,'widthHz',1,'reduction',0.5}, ...
		'where', {@where_heuristic, 'position','rightMC'} }};

In the above, the first specification is a timeline generator configuration
and the second specifies one signal component which is triggered by the timeline. 
The cortical phenomena to be classified is specified to be made by the 
generator '@gen_desync' which is a function handle to file 'what/gen_desync.m'.
This function will be given {'centerHz',12,'widthHz',1,'reduction',0.5}
as parameters. The framework does not know the parameters a function supports,
only the function itself does.

Parameter lists can be either written by hand, or existing parameter lists can
be modified with convenience functions get_parameter(), set_parameter(), 
get_parameter_in_context(), and set_parameter_in_context().

If the user wishes to explore the effects of different parameters, this is done
by specifying 'key,value' pair where instead of value, loop_these() is used.

Example:

% Specification of classification pipelines to be tested.
allPipelines = { ...
	{'name','lda', 'classEvents', classEvents, 'processors', { ...
	  {@proc_lda, 'tikhonov', loop_these([0.01 0.1 0.25 0.5 0.75 1.0],'tikhonov')} } }
};

These 'unexpanded' parameters are given to BCI Simulator, which will then
create actual parameter lists by expanding the values specified by loop_these()
in all the possible combinations (if multiple loop_these() are specified to the
same parameter list). For example, expanding the above would create 3 new lists,
one for each value specified by loop_these().


Other Details
-------------

Data generation
---------------
core_data_generator.m - Given generative specification, outputs a dataset. It uses

  core_head.m - A head model. E.g. for the heads' forward transform.
  core_timeline.m - Class to generate timelines
  
 
Stages of classification
------------------------
core_pipeline.m - Given pipeline specification & data, estimates DSP pipelines
    train() - Given a dataset and pipeline params, estimates a classification (signal processing) pipeline
    process() - Makes predictions on new surface data
	

Putting them together
---------------------
core_bci_simulator.m - Given generative and signal processing parameters, run experiments

Internally, the class has a few member functions,

  run_experiment() :  Runs required amount of iterations and caching results
  run_iteration()  :  (Private) Run a single iteration with given parameters (generate data + train pipelines + test pipelines)

The constructor of the class expands parameters (e.g. loops) in the parameter lists.


Other notes
-----------
By default the framework generates & classifies trials. If there are 20 trials, it means that the whole EEG time-series 
of nTrials * trialLength * samplingFreq samples at the electrodes will be eventually *condensed* just to 20 
feature vectors to classify by the signal processors in the pipeline. Some feature extractors, like CSP, work on the raw, 
non-aggregated data, and require per-sample labels. That is why the trainData and testData structures contain both 
'trial labels' and 'sample labels'. But we don't necessarily do classification per EEG sample, but per-trial. 
Some BCI pipelines like the OpenViBE motor imagery classify 'chunks' that are smaller than the trial size and then 
decide the trial label by voting. Here we simply expect that the last processor of the pipeline will return one
vector per trial, where the components of the vector are likelihood that the trial belongs to the class. The
platform will then take argmax as the label.


Howto
-----
See pretty pictures:
	Consult examples/example_visualize.m
	
Change the physical/forward/head model: 
	Provide a new .mat file similar to those listed in 'headParams' at the beginning of 'classifytest.m'. 
	The .mat file can also contain any data related to the inverse transform. The model must be correctly
	oriented (see above).

Change how the volume data is mapped to the surface:
	Change/add to core_head.forward_transform()
	
Change how simulated data & brain states are generated in the volume:
	Write a custom generator to what/ and spec its function handle to generateParams.
	
Change/add a processing module:
    Edit/add a class in classifiers/ or extractors/
	Change 'pipelineParams' in 'classifytest.m' to call the new part
	
Change pipeline or classifier:
	Modify parameter lists, provide new class handles

Change noise properties and weights:
	Modify parameter lists, provide new noise function handles

Visualize a generated dataset:
	Use 'visualize_dataset.m'
	
Visualize a physical model (sources and electrode positions in the volume):
	Use core_head.visualize() 
	

Known issues
------------
- If you change simulation parameters, and rerun, bciSIM will use old results from the cache. Remember to delete the cache before rerunning.

