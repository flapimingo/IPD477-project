

classdef proc_erp_template
	% Computes mean ERP response per channel for all trials belonging to
	% class 1. Each mean vector is then treated as a matched filter and
	% applied with convolution to the corresponding channel of new data in process().
	% The feature returned per channel is the max response of this convolution
	% per trial. Intuitively, the feature response is expected to be high when
	% the pattern represented by the filter matches well to the trial.

	properties
		filters
		usedParams
	end

	methods

	function [ obj,feats ] = train(obj, trainData, varargin)
		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'visualize',              false,    @islogical);

		p.parse(varargin{:});
		params = p.Results;

		%%%%%%%%%%%

		assert(trainData.numClasses==2);

		grandAvg = [];

		for i=1:trainData.numTrials
			if(trainData.trialLabels(i)==1)
				trialData = trainData.X(trainData.trialIds==i,:);
				if(isempty(grandAvg))
					grandAvg = trialData;
				else
					% if trials have different sizes, we return filters matching the smallest
					xDim = min(size(grandAvg,1),size(trialData,1));
					grandAvg = grandAvg(1:xDim,:) + trialData(1:xDim,:);
				end
			end
		end
		if(isempty(grandAvg))
			% There's no in-class examples, pass a DC filter for all channels
			grandAvg = ones(trainData.samplingFreq, size(trainData.X,2));
		else
			grandAvg = grandAvg ./ sum(trainData.trialLabels==1);
			grandAvg = normalize(grandAvg);
		end

		obj.filters = grandAvg;
		obj.usedParams = params;

		feats = [];

		if(params.visualize)
			figure();imagesc(grandAvg); title('ERP Template filters'); ylabel('Time'); xlabel('Channel');
		end
	end

	function feats = process(obj, data)

		assert(size(data.X,2)==size(obj.filters,2));

		for i=1:size(obj.filters,2)
			data.X(:,i) = conv(data.X(:,i),obj.filters(:,i),'same');
		end

		feats = zeros(data.numTrials, size(data.X,2));
		for i=1:data.numTrials
			dataChunk = data.X(data.trialIds==i,:);
			feats(i,:) = max(dataChunk,[],1);
		end

	end

	end

end
