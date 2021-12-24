
function [noise,details,params] = noise_spectrally_colored( sizeof, varargin )
% Concatenate the different types of surface noise used in the BCI Comp IV review paper (4.2.1, 4.2.2)

	p = inputParser;
	p.KeepUnmatched = false;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'dataset',                [],             @isstruct);
	addParameter(p, 'mask',                   [],             @isnumeric); 
	addParameter(p, 'physicalModel',          @null,          @ishead);
	addParameter(p, 'strength',               [1.0,0.5,0.3],  @isnumeric);
	addParameter(p, 'subType',                'fake',         @ischar);
	addParameter(p, 'sourceFile',             '/path/src.mat',@ischar);
	addParameter(p, 'exponent',               1.7,            @isnumeric);
	addParameter(p, 'visualize',              false,          @islogical);

	p.parse(varargin{:});
	params = p.Results;

	%%%%%%%%%

	assert(~isempty(params.dataset));
	assert(~isequal(params.physicalModel,@null));
	assert(size(params.physicalModel.electrodePos,1)==sizeof(2), 'For this noise type, number of channels requested should match head model electrode count');

	samplingFreq = params.dataset.samplingFreq;
	physicalModel = params.physicalModel;

	% fprintf(1, 'Estimating cross spectrum...\n');
	if(strcmp(params.subType, 'spatial'))
		% Artificial spatial correlation. Easiest to understand.
		% this generation appears to be more stable in its cov
		% characteristics from run to another, if the drifts are
		% disabled.
		spectralModel = estimate_cross_spectrum([], sizeof, samplingFreq, physicalModel, params.visualize);
		spectralModel.type = 'spatial';		% override
	elseif(strcmp(params.subType, 'fake'))
		% Artificial spectral correlation, same for all frequencies.
		spectralModel = estimate_cross_spectrum([], sizeof, samplingFreq, physicalModel, params.visualize);
	elseif(strcmp(params.subType, 'dataDriven'))
		% Data-driven spectral correlation trying to mimic the statistics of the file.
		% This is the one actually in the paper. Assumed the file follows the conventions of the platform
		dat = load(expand_path(params.sourceFile));
		if(~isempty(physicalModel.electrodesDiscarded) && ...
			size(dat.X,2) == size(physicalModel.A,1) + length(physicalModel.electrodesDiscarded))
			% Appears some electrodes have been discarded; cut them from the recording
			electrodesToKeep = setdiff(1:size(dat.X, 2), physicalModel.electrodesDiscarded);
			dat.X = dat.X(:,electrodesToKeep);
		end
		assert(size(dat.X,2)==sizeof(2), 'Noise source template file channel count must match head model electrode count');
		assert(dat.samplingFreq == samplingFreq);

		spectralModel = estimate_cross_spectrum(dat.X, [], samplingFreq, [], params.visualize);
	elseif(strcmp(params.subType, 'prebuilt'))
		% Load a prebuilt model from disk
		spectralModel = load(expand_path(params.sourceFile));
		assert(size(spectralModel,1) == physicalModel.A,2);
	else
		assert(false, 'Unknown bcicomp4 subtype');
	end

	% Note that components from sections 4.2.3, 4.2.4 and 4.2.5 will be generated in the volume.
	coef = params.strength;
	noise =         coef(1) .* generate_colored_noise(spectralModel, samplingFreq, params, sizeof(1), 1, 1);    % background noise, bci comp iv 4.2.1
	noise = noise + coef(2) .* generate_colored_noise(spectralModel, samplingFreq, params, sizeof(1), 150, 0);  % drift 1, bci comp iv 4.2.2
	noise = noise + coef(3) .* generate_colored_noise(spectralModel, samplingFreq, params, sizeof(1), 300, 0);  % drift 2, bci comp iv 4.2.2

	if(~isempty(params.mask))
		noise = noise .* repmat(params.mask, [1 sizeof(2)]);
	end
	
	details = [];

	if(params.visualize)
		numChn = min(9,size(noise,2));
		subPlots = ceil(sqrt(numChn));
		figure();
		yMax = max(max(noise(:,1:numChn)));
		yMin = min(min(noise(:,1:numChn)));

		for i=1:numChn
			subplot( subPlots, subPlots, i);
			plot( (0:sizeof(1)-1)/samplingFreq, noise(:,i));
			xlabel('Time');ylabel('Amplitude');
			ylim([yMin yMax]);
			title(sprintf('bcicomp4 noise: chn %d', i));
		end
	end
end

