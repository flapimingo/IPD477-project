
function [sourceActivity,details,params] = gen_desync( sizeof, varargin )
% 
% Desynchronize activity in a specific band in some condition.
%
% Allows to generate BCI Competition IV signal part, Tangermann & al. 2012
%
% Implements paper sections 4.2.3 and 4.2.4
%
% To get laterality bias, call several times for different sides. 
% If all sides are damped equally, then there is no laterality bias.
% The paper default is 0.5 (==50%) for both dampening factors.
%
%	
%
	% parse arguments
	p = inputParser;
	p.KeepUnmatched = false;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'dataset',                [],    @isstruct);
	addParameter(p, 'physicalModel',          core_head); % not used
	addParameter(p, 'mask',                   [],    @isnumeric);       % 0/1 per sample, when to desync?
	addParameter(p, 'sourceType',             0,     @isint);			% paper uses Gaussians
	addParameter(p, 'doFilter',               true,  @islogical);		% If false, the source activity will be wideband.
	addParameter(p, 'centerHz',               12,    @isnumeric);		% if filtering is enabled, it will pass through the center+/-width band and the 1st harmonic. In paper, 12 is used.
	addParameter(p, 'widthHz',                1,     @isnumeric);		% In paper, 1 is used
	addParameter(p, 'harmonicWeight',         0.08,  @isnumeric);		% paper mentions range 0.01 to 0.15.
	addParameter(p, 'reduction',              0.5,   @isnumeric);		% reduction in the rhythmic activity; small value = less reduction, difficult. Paper: 0.5 and more.
	addParameter(p, 'doNormalize',            false, @islogical);		% paper: not present, so false	
	addParameter(p, 'exponent',               1.7,   @isnumeric);		% Parameter for pink noise and used to normalize (if enabled). Not in the paper.

	p.parse(varargin{:});
	params = p.Results;

	%%%%%%%%%

	numSamples = sizeof(1);
	numSources = sizeof(2);
	samplingFreq = params.dataset.samplingFreq;

	% Select the type of source activity
	if(params.sourceType==0)
		% all sources independent gaussian; this is the choice in the paper
		nonFilteredActivity = randn(numSamples, numSources);
	elseif(params.sourceType==1)
		% sources are all Gaussian clones
		nonFilteredActivity = repmat(randn(numSamples, 1), [1 numSources]);
	elseif(params.sourceType==2)
		% sources are nongaussian
		nonFilteredActivity = sign(rand(numSamples, numSources)-0.5).*log(rand(numSamples,numSources));
	elseif(params.sourceType==3)
		% sources are nongaussian clones
		nonG = sign(rand(numSamples, 1)-0.5).*log(rand(numSamples,1));
		nonFilteredActivity = repmat(nonG, [1 numSources]);
	elseif(params.sourceType==4)
		% sources are independent pink
		nonFilteredActivity = noise_pink([numSamples numSources],'exponent',params.exponent);
	else
		assert(false, 'Unknown source type');
	end

	% Filter to a narrow band or not?
	if(params.doFilter)
		sourceActivity = filter_bandpass(nonFilteredActivity, samplingFreq,...
				params.centerHz-params.widthHz, ...
				params.centerHz+params.widthHz);

		% Add 1st harmonic, section 4.2.4
		sourceActivity = sourceActivity + params.harmonicWeight .* ...
			filter_bandpass(nonFilteredActivity, samplingFreq, ...
				2*params.centerHz-params.widthHz, ...
				2*params.centerHz+params.widthHz);
	else
		sourceActivity = nonFilteredActivity;
	end

	% How much to dampen?
	assert(all(params.reduction>=0 & params.reduction<=1));
	if(length(params.reduction)==1)
		reduction = repmat(params.reduction, [1 numSources]);
	else
		reduction = params.reduction;
	end


	% Dampen source depending on condition + bias. BCI Comp IV sections 4.2.3 and 4.2.5.
	%
	for i=1:numSources
		% This creates a mask that will wary between [reduction,1],
		% The value of the weighted mask is supposed to be *low* for in-class samples
		weightedMask = ones(numSamples,1);
		weightedMask(params.mask==1) = (1-reduction(i));

		% Dampen source power in the in-class condition ('beta depression')
		sourceActivity(:, i) = weightedMask .* sourceActivity(:,i);
	end

	% make the non-zero sources have zero mean and unit variance, then rescale using the center frequency
	% (to mix with 1/f^n spectrum noise; this scaling is not in the BCI Comp IV paper but may make component mixing more intuitive)
	if(params.doNormalize)
		sourceActivity = normalize(sourceActivity) .* 1/sqrt(params.centerHz^params.exponent);
	end

	details = [];

end

