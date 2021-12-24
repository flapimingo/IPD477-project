
function [S,details,params] = gen_ssvep( sizeof, varargin)
% Attempts to generate a signal that models the expected cortical response
% to the SSVEP paradigm flicker. Roughly, flicker of certain frequency
% on the screen is expected to elicite a boost of the similar frequency in
% the users occipital lobe.
%
% If multiple sources are requested, they will be clones of each other. The
% difference in the signal is in the time domain: different frequency
% is active depending on which target the subject attends.
%
% @TODO realism could likely be greatly improved
%

	% parse arguments
	p = inputParser;
	p.KeepUnmatched = false;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'dataset',                [],    @isstruct);
	addParameter(p, 'physicalModel',          core_head);		 % not used
	addParameter(p, 'flickerHz',              7.0,     @isnumeric);
	addParameter(p, 'mask',                   [],      @isnumeric);
	addParameter(p, 'visualize',              false,  @islogical);

	p.parse(varargin{:});
	params = p.Results;

	%%%%%%%%%%%%

	numSamples = sizeof(1);
	numSources = sizeof(2);
	samplingFreq = params.dataset.samplingFreq;

	% Generate requested frequency
	S = noise_frequency_spike( [numSamples, numSources], 'dataset', params.dataset, ...
			'frequencyHz', params.flickerHz, 'harmonics', true);

	% Set this activity to zero for off-class
	S = repmat( (params.mask==1),[1 numSources]) .* S;

	if(params.visualize)
		figure(); spectrogram(S(:,1),100,[],[],samplingFreq); title('SSVEP activity');
	end

	details = [];

end

