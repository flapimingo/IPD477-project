
function [S,details,params] = gen_p300( sizeof, varargin)
% Attempts to generate a signal that models the expected cortical response
% to P300 flashes. Roughly, when flash hits an attended target, it should
% elicite a specific event-related potential (ERP) pattern in the time/sample
% space (and no pattern for unattended targets).
%
% If multiple sources are requested, they will be clones of each other.
%
% @TODO realism could likely be greatly improved. This is just presented
% as an illustration.
%

	% parse arguments
	p = inputParser;
	p.KeepUnmatched = false;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'dataset',                [],    @isstruct);
	addParameter(p, 'mask',                   [],    @isnumeric);		% when do the events happen
	addParameter(p, 'physicalModel',          core_head);	 % not used
	addParameter(p, 'visualize',              false,  @islogical);

	p.parse(varargin{:});
	params = p.Results;

	%%%%%%%%%%%%

	numSamples = sizeof(1);
	numSources = sizeof(2);
	samplingFreq = params.dataset.samplingFreq;

	% Make a very adhoc P300 pattern: weight Beta function with a Gaussian
	sampleStep = 1/samplingFreq;
	lp = -1:sampleStep:1;
	bump = exp(-(lp-0.3).^2/0.01).*(lp.^(2-1)).*(1-lp).^(5-1);
	bump(1:floor(length(bump)/2)) = 0;
	bump2 = circshift(bump, [1 -floor(0.01*samplingFreq)]);
	pattern = -bump + 0.9*bump2;
	pattern = pattern/max(abs(pattern));

	% First class is assumed to be the attended class; generate patterns
	% at first-class onsets
	impulse = diff(params.mask);
	impulse(impulse<0) = 0;
	impulse = [impulse;0];
	activity = conv(impulse, pattern, 'same');

	% If multiple source locations are requested, they will just be clones in this case
	S = repmat(activity, [1 numSources]);

	if(params.visualize)
		figure(); plot((0:numSamples-1)/samplingFreq, S(:,1)); title('P300 patterns'); xlabel('Secs'); ylabel('Amplitude');
	end

	details=[];

end
