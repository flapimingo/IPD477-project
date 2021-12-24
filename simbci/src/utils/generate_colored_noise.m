%
% generate 'nSamples' new samples having the same spectral characteristics as 'source'.
%
% 'Multiplier' > 1 can be used to squeeze the spectrum towards the low frequencies
% to generate slow 'baseline drifts'.
%
% The function can be used as part of a pipeline to replicate the BCI Competition IV
% artifical dataset (Tangermann & al. 2012, sections 4.2.1 and 4.2.2)
%
% Output f contains the summed eigenvalues per each frequency slice of the interpolated spectrum.
%
function [noiseColored, interpolatedSpectrum, f] = generate_colored_noise(spectralModel, samplingFreq, noiseParams, nSamples, multiplier, doPlot)

	if(nargin<4)
		multiplier = 1;
	end
	if(nargin<5)
		doPlot = 0;
	end

	dim = size(spectralModel.crossSpectrum,1);

	nSamplesModded = false;
	if rem(nSamples,2)
		nSamples=nSamples + 1;
		nSamplesModded = true;
	end

	% Due to FFT symmetry ...
	uniquePts = nSamples/2 + 1;

	interpolatedSpectrum = [];
	f=[];

	if(strcmp(spectralModel.type,'spatial'))
		% This creates pink 1/f noise which is then specified a spatial cov structure

		% Create pink noise
		noiseGen = dsp.ColoredNoise('InverseFrequencyPower',noiseParams.exponent,'NumChannels',dim,'SamplesPerFrame',nSamples);
		noisePink = noiseGen.step();

		% Transform the pink noise to be spatially white.
		co = cov(noisePink);
		[E,D] = eig(co);
		whiteningMatrix = inv (sqrt (D)) * E';
		whitenedNoise = (whiteningMatrix * noisePink')';

		% Transform it to have a preferred spatial covariance spectrum
		[ETarget,DTarget] = eig(spectralModel.crossSpectrum);
		dewhiteningMatrix = ETarget * sqrt (DTarget);
		noiseColored = (dewhiteningMatrix * whitenedNoise')';

	elseif(strcmp(spectralModel.type,'fake'))
		% Generates Gaussian white noise, maps it to time-frequency space, modulating it to
		% have a specified 1/f type slope and spectral covariance structure, identical for every frequency.

		% Generate Gaussian white noise and convert to the freq space
		noiseFFTColored = fft( randn(nSamples, dim) );

		% in this case the cross spectrum is same for each freq, and we add an 1/freq power law here.
		% n.b. In total, this probably resembles generating pink noise and enforcing a spatial cov structure for it.
		[E,D] = eig(spectralModel.crossSpectrum);
		%figure(1); imagesc(E); drawnow;
		targetFrequencies = linspace(0, multiplier*samplingFreq/2, uniquePts);
		% Filter the white noise to give it the desired covariance structure
		noiseFFTColored = noiseFFTColored*real(E*sqrt(D))';
		noiseFFTColored(1,:) = 0;	% zero DC

		weighting = 1./sqrt(targetFrequencies(2:end).^noiseParams.exponent);
		noiseFFTColored(2:uniquePts,:) = noiseFFTColored(2:uniquePts,:) .* repmat(weighting', [1 size(noiseFFTColored,2)]);

		noiseFFTColored(uniquePts+1:nSamples,:) = real(noiseFFTColored(nSamples/2:-1:2,:)) -1i*imag(noiseFFTColored(nSamples/2:-1:2,:));

		noiseColored = real(ifft(noiseFFTColored));

	else
		% Generates Gaussian white noise, maps it to time-frequency space, modulating it to
		% have a specified spectral covariance structure which can be different for each frequency.
		% The followed frequency power law comes from the spectral model.
		%
		% TODO this computation for big, dense datasets is very very slow. Maybe
		% it could be made faster or at least have a smaller memory footprint by
		% doing the interpolation manually at each step in the uniquepts loop. Also,
		% instead of eigdecomposing each slice separately, maybe the orignal
		% stack could be decomposed and then the interpolation done for the eigs?

		% Generate Gaussian white noise and convert to the freq space
		noiseFFTColored = fft( randn(nSamples, dim) );

		% In this case we have a different spectral covariance for every freq.
		% Interpolate the spectrum stack to match the generated dataset size
		interpolatedSpectrum = zeros(dim,dim,uniquePts);
		targetFrequencies = linspace(0, multiplier*spectralModel.frequencies(end), uniquePts);
		for i=1:dim
			for j=i:dim
				spectrum = squeeze(spectralModel.crossSpectrum(i,j,:));
				%xpowerInterp = imresize(spectrum, [uniquePts 1],'bilinear');
				xpowerInterp = interp1(spectralModel.frequencies, spectrum(:), targetFrequencies, 'linear',0);
				interpolatedSpectrum(i,j,:) = xpowerInterp;
				interpolatedSpectrum(j,i,:) = conj(xpowerInterp);
			end
		end

		% fprintf(1,'Generating noise');

		% Filter the white noise to give it the desired spectral covariance structure

		% Due to fft symmetry we can do just the half and mirror the rest
		f=zeros(1,uniquePts);
		for i=1:uniquePts
	%		if(rem(i,5000)==0) fprintf(1, '.'); end
			freqCov = interpolatedSpectrum(:,:,i);
			[E,D] = eig(freqCov);
			noiseFFTColored(i,:) = ((E*sqrt(D))*noiseFFTColored(i,:)')';
			f(i)=sum(real(sqrt(diag(D))));
		end
	%	plot(f);
	%	fprintf(1,'\n');

		noiseFFTColored(uniquePts+1:nSamples,:) = real(noiseFFTColored(nSamples/2:-1:2,:)) -1i*imag(noiseFFTColored(nSamples/2:-1:2,:));

		noiseColored = real(ifft(noiseFFTColored));

	end


	if(0)
		% force sources spatial covariance structure. Note that this may adversely affect the earlier spectral structuring we did.
		[E1,D1] = eig(cov(noiseColored));
		noiseColoredWhite = noiseColored*real(E1*sqrt(pinv(D1)));
		[E2,D2] = eig(spectralModel.cov);
		noiseColored = (real(E2*sqrt(D2))*noiseColoredWhite')';
	end

	% set the channel means and variances from the original signal
	%
	% First scale to 0 mean, unit variance 	and then specify these params from the sample data
	noiseColored = normalize(noiseColored);
	noiseColored = noiseColored .* repmat( spectralModel.std, [size(noiseColored,1) 1]);
	noiseColored = noiseColored + repmat( spectralModel.mean, [size(noiseColored,1) 1]);

	if(nSamplesModded)
		noiseColored = noiseColored(1:nSamples-1,:);
	end

