
function [noise,details,params] = noise_eyemovement( sizeof, varargin )
	% Attempts to implement the BCI Comp IV review paper section 4.2.6: eye movement

	% parse arguments
	p = inputParser;
	p.KeepUnmatched = false;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'dataset',                [],    @isstruct);
	addParameter(p, 'physicalModel',          core_head, @ishead);
	addParameter(p, 'mask',                   [],    @isnumeric); % when do the moves occur?
	addParameter(p, 'eyemoveAmplitude',       1,     @isnumeric);
	addParameter(p, 'visualize',              false, @islogical);

	p.parse(varargin{:});
	params = p.Results;

	%%%%%%%%%%%%%%

	if(params.physicalModel.constrainedOrientation)
		noiseMultiplier = ones([1 sizeof(2)]);
	else
		% If we're generating for a free dipole orientation case, weight directions differently
		assert(rem(sizeof(2),3)==0, 'Expected source count to be divisible by 3 in nonconstrained case');
		noiseMultiplier = repmat([1 0 10], [1 sizeof(2)/3]);
	end

	% Weight gaussian noise at the eye dipoles with the mask that contains the durations already. All other dipoles are 0.

	% @fixme, don't really understand what are the papers vertical and horizontal dipoles.
	% here its assumed leftEye is x y z and that z=vert, x=horiz.
	% here take 6 dims of random noise, 3 for each eye. Weight noise by the power from the timeline and then based if its
	% horizontal or vertical (10x vertical, 1x horiz) = noiseMultiplier. In the constrained orientation case, just 1 dim.
	noise = randn(sizeof) .* repmat(params.mask, [1 sizeof(2)]) .* repmat(noiseMultiplier , [sizeof(1) 1]);

	% n.b. eyemoves are already generated by mask, so we don't remask

	details=[];

	if(params.visualize)
		figure();
		yMax = max(noise(:));
		yMin = min(noise(:));

		for i=1:size(noise,2)
			subplot(size(noise,2),1,i);
			plot( (0:sizeof(1)-1)/samplingFreq, noise(:,i) );
			title(sprintf('Eyemove artifacts: chn %d', i));
			ylim([yMin yMax]);
			xlabel('Time');ylabel('Amplitude');
		end

		drawnow;
	end

end

