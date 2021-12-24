

classdef proc_downsample
% Downsamples a dataset. At the moment the new frequency must be old frequency divided by integer.
%
% Process() returns a new downsampled dataset.
%
% Note that this also affects the supplementary information such as class label vectors etc in the dataset.
% 

	properties
		downsampleSteps
		origFreq
		
		usedParams
	end

	methods

	function [ obj,feats ] = train(obj, trainData, varargin)

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'newFreq',              100,    @isnumeric);

		p.parse(varargin{:});
		obj.usedParams = p.Results;

		%%%%%%%%%%%
		
		newFreq = obj.usedParams.newFreq;
		obj.origFreq = trainData.samplingFreq;
		
		assert(obj.origFreq >= newFreq, 'Can not downsample to higher frequency');
		assert(mod(obj.origFreq, newFreq) == 0, 'Only supporting downsample to multiple freqs')

		obj.downsampleSteps = trainData.samplingFreq / newFreq; % number of elements to skip in the signal

		% on demand
		feats = [];

	end

	function data = process(obj, data)

		assert(~isempty(obj.downsampleSteps));
		assert(data.samplingFreq == obj.origFreq);
		
		stepIdx = 1:obj.downsampleSteps:size(data.X,1);
		
		% Since we modified the number of samples, we also need to modify
		% all the supplementary information
		data.X = data.X(stepIdx,:);
		data.samplingFreq = obj.usedParams.newFreq;
		if(isfield(data,'trialIds'))
			data.trialIds = data.trialIds(stepIdx);
		end
		if(isfield(data,'sampleLabels'))
			data.sampleLabels = data.sampleLabels(stepIdx);
		end
		if(isfield(data,'events'))
			for i=1:length(data.events)
				% in samples, so integers
				data.events(i).latency = floor(data.events(i).latency/obj.downsampleSteps)+1;
				data.events(i).duration = floor(data.events(i).duration/obj.downsampleSteps);
			end
		end		
		data.numSamples = size(data.X,1);	
	end

	end

end


