
%
% Estimate cross spectrum of a given dataset. The spectrum can be later used to generate
% noise with the similar spectral characteristics.
%
% The function can be used as part of a pipeline to replicate the BCI Competition IV
% artifical dataset (Tangermann & al. 2012, sections 4.2.1 and 4.2.2)
%
function spectralModel = estimate_cross_spectrum(source, sizeof, freq, physicalModel, doPlot)

	if(nargin<5)
		doPlot = false;
	end

	if(~isempty(source))
		% estimate the cross-spectrum model from real data in 'source'

		% Todo: Possibly a reasonable way to get a decent, smooth estimate would be to average the cross-spectrums
		% from several recordings. But this might lose the correlations dependending on changes in conditions.

		[nSamples,nChannels]=size(source);

		%fprintf(1,'Estimating cross spectrum...');

		% window = 8744;
		window = 2048;
		% window = 128;
		% window = []; % matlab default

		% Run the cpsd once to obtain the number of estimates
		tmp = cpsd(source(:,1),source(:,1),window,[],[],freq);
		nPowerEstimates = size(tmp,1);

		% @TODO this computation could probably be much more faster, likely now
		% the same fft transforms are done over and over again in cpsd. However, the
		% n(n-1)/2 nested loops [ i.e. p=cspd(i,j)] is not faster.
		crossSpectrum = zeros(nChannels,nChannels,nPowerEstimates);
		for i=1:nChannels
			[xpower,frequencies] = cpsd(source(:,i),source,window,[],[],freq);
			crossSpectrum(i,:,:) = xpower';

%			fprintf(1,'.');
		end
%		fprintf('\n');

		if(0)
			% slower
			crossSpectrum2 = zeros(nChannels,nChannels,nPowerEstimates);
			for i=1:nChannels
				for j=i:nChannels
					[xpower,frequencies] = cpsd(source(:,i),source(:,j),window,[],[],freq);
					crossSpectrum2(i,j,:) = xpower;
					crossSpectrum2(j,i,:) = conj(xpower);	% symmetry
				end
				fprintf(1,'.');
			end
			fprintf('\n');
		end

		spectralModel=[];
		spectralModel.crossSpectrum = crossSpectrum;
		spectralModel.frequencies = frequencies;
		spectralModel.type='estimated';
		spectralModel.mean = mean(source);
		spectralModel.std = std(source);
		spectralModel.cov = cov(source);
		spectralModel.window = window;

		if(doPlot)

			figure();
			imagesc(crossSpectrum(:,:,1));
			title('First slice of the estimated cross spectrum');
			xlabel('Electrode'); ylabel('Electrode');
		end

	else
		%
		% In this case we don't have data, just make an ad-hoc spectrum based on electrode distances:
		% the close electrodes have stronger dependency.
		% This will be the same for all frequencies.
		%
		nChannels = sizeof(2);

		assert(size(physicalModel.electrodePos,1) == nChannels, 'Physical model electrode count must match requested number of channels');

		% Weight the spectrum so that channels which are close by are more correlated (gaussian weighted distance)
		crossSpectrum = zeros(nChannels, nChannels);
		for i=1:nChannels
			for j=i:nChannels
				d = norm(physicalModel.electrodePos(i,:) - physicalModel.electrodePos(j,:));
				crossSpectrum(i,j) = exp(-(d.^2));
				crossSpectrum(j,i) = crossSpectrum(i,j);
			end
		end

		spectralModel=[];
		spectralModel.crossSpectrum = crossSpectrum;
		spectralModel.frequencies = [];
		spectralModel.type = 'fake';
		spectralModel.mean = zeros(1, nChannels);
		spectralModel.std = ones(1,nChannels);

		if(doPlot)

			figure();
			imagesc(crossSpectrum);
			title('Fake cross spectrum');
			xlabel('Electrode'); ylabel('Electrode');
			% ...

		end


	end

