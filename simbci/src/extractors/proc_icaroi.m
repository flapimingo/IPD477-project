

classdef proc_icaroi
	% ROI sources using Independent Components Analysis
	%
	% Uses ICA on the signal and computes a T/F Representation (TFR) of the ICA components. 
	% These TFRs are correlated with a class identity mask to compute how much affinity each component
	% has to the class variability. The ICA forward matrix A templates for the best components
	% are selected, and each template is then projected to the volume using the selected inverse 
	% transform. The most active coefficients in the volume are used to select a ROI for the
	% component. Finally, the code returns the volume activities of the sources in all the 
	% selected ROIs (i.e. the output is just an inverse transform of the signal with sources 
	% inside all the ROIs returned).
	%
	% This approach is inspired by
	% 
	% Edelman & He, "EEG Source Imaging Enhances the Decoding of Complex Right-Hand Motor Imagery Tasks", 2016.
	%
	
	properties
		forwardModel
		inverseModel
		
		icaModel
		tfrModel
		downSampler
		
		selectedSources
		debugData
		
		usedParams
	end
	methods
		
	function [obj,feats] = train(obj, trainData, varargin)
	% Trains the icaroi feature extractor
	%
	% Internally this code relies on composition of some subprocessors since we need
	% to access their by-products, e.g. the ICA mixing matrix A.
	%
	
		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'forward',                @core_head,      @isfunlist);	 % forward model	
		addParameter(p, 'inverse',                @wmn_inverse,    @isfun);	     % inverse algorithms
		addParameter(p, 'icaParams',              {},              @iscell);     % parameters given to ICA
		addParameter(p, 'tfrParams',              {},              @iscell);     % parameters to make T/F representation
		addParameter(p, 'downsampleFreq',         100,             @isnumeric);  % Downsample before TFR
		addParameter(p, 'keepDims',               4,               @isint);		 % How many ROIs(!) to keep		 
		addParameter(p, 'activationThreshold',    0.75,            @isnumeric);	 % Threshold for source to be selected, prct
		addParameter(p, 'visualize',              false,           @islogical); 
		
		p.parse(varargin{:});
		params = p.Results;

		%%%%%%%
		
		% Load the head model
		[headFun,headParams] = split_funlist(params.forward);
		obj.forwardModel = headFun(headParams{:});
		
		% Construct the ICA and the TFR models. 
		obj.icaModel = proc_ica().train(trainData,params.icaParams{:});
		obj.tfrModel = proc_tfr().train(trainData,params.tfrParams{:});
		obj.downSampler = proc_downsample().train(trainData,'newFreq',params.downsampleFreq);
		
		%% Compute ICA
		icaS = obj.icaModel.process(trainData);

		%% Make TFR of the downsampled ICA components
		trainData.X = icaS;
		trainData = obj.downSampler.process(trainData);
		params.keepDims = min(size(trainData.X,2),params.keepDims);
		TFR = obj.tfrModel.process(trainData);
		
		% Compute how well each ICA component matches to a predefined mask in the TFR. 
		% Basically an on/off mask should correlate with the wavelet power at some freq of interest
		[numSamples,numChannels] = size(trainData.X);
		
		featsPerChannel = size(TFR,2)/numChannels;
		
		scores = zeros(trainData.numClasses,numChannels);
		
		chn = 1;
		for i=1:size(TFR,2)
			for j=1:trainData.numClasses
				co = corrcoef(TFR(:,i), double(trainData.sampleLabels==j)); % correlate with class mask
			
				scores(j,chn)=scores(j,chn)+abs(co(1,2));  % both negative and positive correlations can be useful
			end
			
			if(rem(i,featsPerChannel)==0)
				chn = chn + 1;
			end
		end
		
		totalScorePerChn = sum(scores,1);
		
		if(params.visualize)
			figure(); 
			subplot(1,2,1); imagesc(scores); xlabel('ICA comp'); ylabel('Class'); colorbar; title('Scores');
			subplot(1,2,2); plot(totalScorePerChn); xlabel('ICA comp'); ylabel('Score'); title('Scores per ICA component');
		end
		
		% Pick the best matching ICA components
		[~,componentIdx] = sort(totalScorePerChn,'descend');

		selectedComponents = componentIdx(1:params.keepDims);

		if(params.visualize)
			figure();
		end
		
		selectedIdxs = [];                      % Union of all ROIs
		selectedROIs = cell(1,params.keepDims); % Cell since we might not have the same number of sources in all ROIs
		for i=1:params.keepDims
			ICAMask = obj.icaModel.model.icaA(:,selectedComponents(i));
			maskInVolume = params.inverse(obj.forwardModel.A, ICAMask, obj.forwardModel.constrainedOrientation);
			maskAbs = abs(maskInVolume);
			% @FIXME for nonconstrained orientation?
			sourceIdx = find(maskAbs>params.activationThreshold*max(maskAbs(:)));
			selectedROIs{i} = sourceIdx;
			selectedIdxs = union(selectedIdxs,sourceIdx);

			if(params.visualize)
				subplot(1,params.keepDims,i);
				tit = sprintf('ICA ROI for comp %d (size=%d)', i, length(sourceIdx));	
				obj.forwardModel.visualize(sourceIdx, [], true); title(tit);
			end
		end

		if(params.visualize)
			figure(); obj.forwardModel.visualize(selectedIdxs, [], true); title('Union of selected ICA ROIs');
		end

		obj.selectedSources = selectedIdxs;	    % sources selected in the volume
		obj.usedParams = params;
		
		% The following variables are not used later, but they may be useful for analysis
		obj.debugData = [];
		obj.debugData.scores = scores;
		obj.debugData.selectedROIs = selectedROIs;
		obj.debugData.numClasses = trainData.numClasses;
				
		feats = [];

	end

	function feats = process(obj, data)

		assert(~isempty(obj.selectedSources));
		
		% First do the inverse
		feats = obj.usedParams.inverse(obj.forwardModel.A,data.X');
		
		% Select the relevant channels in the source space
		feats = feats(obj.selectedSources,:)';  % transpose faster after selection
	
		% @todo since we compute this already in training, we could already
		% return the relevant subset there and not compute again (just for training set).
	end

	end % methods
end
	