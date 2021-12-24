function [S,details,params] = gen_candle( sizeof, varargin )
% Creates a sinusoid signal that is either on or off. 
%
% Output : sinusoid on when mask,  if depression false (mask on means sinusoid active)
%          sinusoid on when ~mask, if depression true (mask on means sinusoid inactive)
%
% Borders are not handled smoothly.
%
% Note that this is not a very realistic source but works for debugging

	% parse arguments
	p = inputParser;
	p.KeepUnmatched = false;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'dataset',                [],    @isstruct);
	addParameter(p, 'physicalModel',          core_head);		 % not used
	addParameter(p, 'centerHz',               12,    @isnumeric);
	addParameter(p, 'depression',             true,  @islogical); % If true, masked source is dampened

	p.parse(varargin{:});
	params = p.Results;

	%%%%

	numSamples = sizeof(1);
	numSources = sizeof(2);
	samplingFreq = params.dataset.samplingFreq;

	S = zeros(numSamples,numSources);

	% Create & modulate a sinusoid at the dipoles
	y = sin (  (0:numSamples-1) * 2*pi / samplingFreq * params.mi_centerHz);

	if(params.depression)
		mask = (params.mask ~= 1);
	else
		mask = (params.mask == 1);
	end

	S = repmat(y',[1 numSources]) .* repmat(mask, [1 numSources]);
	
	details=[];

end

