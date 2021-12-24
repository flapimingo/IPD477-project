
classdef proc_bcilab
	% Classifier wrapper that uses whatever is provided by the BCILAB package
	%
	% It was implemented with bcilab git version dating Sep 2016.
	%
	% Example: Reasonable first-try parameter set for classifying motor imagery,
	% assuming trials are 4 seconds long,
	%
	% allPipelines = {
	% {'name','csp-bcilab', 'processors', { ...
	%  {'call', @proc_bcilab, 'purgeCache', false, 'approach', ...
	%        { 'CSP' 'SignalProcessing', ...
	%		    {'FIRFilter',{'Frequencies',[7 9 28 32],'Type','minimum-phase'}, ...
	%			    'EpochExtraction',[0 4]},'Prediction', ...
	%				{'FeatureExtraction',{'ShrinkageCovariance',true,'PatternPairs',2} }}}}} ...
	% };
	%
	% The cell array provided to 'approach' can contain any specification that BCILAB's bci_train() supports.
	%

	properties
		model
		usedParams
	end

	methods

	function [obj, pred] = train(obj, trainData, varargin )
	% Estimate the classifier

		% these parameters can be whatever that BCILAB accepts for its
		% 'approach' setting.
		bciLabDefaultApproach = {'CSP' 'SignalProcessing',{'EpochExtraction',[0 2]}};

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'call',                   @proc_bcilab,           @isfun);
		addParameter(p, 'approach',               bciLabDefaultApproach,   @iscell);
		addParameter(p, 'purgeCache',             false,                   @islogical); % Warning: clears BCILAB dataset cache

		p.parse(varargin{:});
		obj.usedParams = p.Results;

		%%%
		targetMarkers = cell(1,trainData.numClasses);
		for i=1:trainData.numClasses
			targetMarkers{i} = sprintf('class%02d', i);
		end

		eeg = dataset_to_eeglab(trainData);

		[~,obj.model] = bci_train('Data',eeg, 'Approach', obj.usedParams.approach, ...
			'TargetMarkers',targetMarkers, ...
			'EvaluationScheme', 'off');

		pred = [];
	end

	function raw = process(obj,dataset)
	% Classify new data with a pre-estimated model

		eeg = dataset_to_eeglab(dataset);

		raw = bci_predict(obj.model, eeg);
		raw = raw{2};

		% BCILAB caching the data to disk is not very meaningful
		% in our usecase as we typically never reuse the data after this
		if(obj.usedParams.purgeCache)
			pattern = env_translatepath('temp:/flushedsets/*.sto');
			delete(pattern);
		end

	end

	end

end

