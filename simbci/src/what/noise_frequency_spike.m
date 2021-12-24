
function [noise,details,params] = noise_frequency_spike( sizeof, varargin )
% Generate activity in a specific frequency
% Can be used e.g. to model mains power source noise (50hz or 60hz)

	p = inputParser;
	p.KeepUnmatched = true;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'dataset',                [],    @isstruct);
	addParameter(p, 'mask',                   [],    @isnumeric);
	addParameter(p, 'frequencyHz',            50,  @isnumeric);
	addParameter(p, 'harmonics',            false, @islogical);

	p.parse(varargin{:});
	params = p.Results;

	%%%%%%%%%

	samplingFreq = params.dataset.samplingFreq;

	timeElapsed = (0:sizeof(1)-1)' / samplingFreq;

	frequencySpike = sin(2 * pi * timeElapsed * params.frequencyHz );
	if(params.harmonics)
		power = 0.1; cnt = 2;
		while(params.frequencyHz * cnt <= samplingFreq / 2)
			frequencySpike = frequencySpike + power * sin(2 * pi * timeElapsed * params.frequencyHz * cnt);
			power = power ^ 2;
			cnt = cnt + 1;
		end
	end

	if(~isempty(params.mask))
		frequencySpike = params.mask .* frequencySpike;
	end
	
	% periodogram(frequencySpike,[],[],samplingFreq);

	noise = repmat(frequencySpike, [1 sizeof(2)]);

	details = [];

end

