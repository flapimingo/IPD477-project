
% Test to generate & visualize the noise components in the BCI Competition IV review paper

clear;
close all;

% Parameters of the generated data
samplingFreq = 200;
nSecs = 3*60;
nSamples = nSecs * samplingFreq;

noiseParams=[];
noiseParams.exponent = 1.7;
noiseParams.samplingFreq = samplingFreq;

physicalModel = load('models/sphere/leadfield_256elec_sigma15');

if(0)
	%
	% A real recording is needed to estimate the spectral characteristics
	%
	dat=load('C:/jl/datasets/motor-imagery-rennes-jussi-gtec2008-20160104/motor-imagery-csp-4-online-[2016.01.04-15.18.47].mat');
	%dat=load('C:/jl/datasets/motor-imagery-rennes-jussi-gtec2008-20160104/motor-imagery-csp-4-online-[2016.01.04-15.23.42].mat');
	%dat=load('C:/jl/datasets/motor-imagery-rennes-jussi-gtec2008-20160104/motor-imagery-csp-4-online-[2016.01.04-15.29.04].mat');
	goodChns = 6:16;
	samples=dat.samples(:,goodChns);
	%fprintf(1, 'Estimating cross spectrum...\n');
	spectralModel = estimate_cross_spectrum(samples, [], dat.samplingFreq, physicalModel);

	visualize_dataset(samples, dat.samplingFreq, 15, 'Source');

	nSamples=size(samples,1);
	samplingFreq = dat.samplingFreq;
	noiseParams.samplingFreq = dat.samplingFreq;

else
	% Artificial spectral structure
	spectralModel = estimate_cross_spectrum([], [nSecs size(physicalModel.electrodePos,1)], samplingFreq, physicalModel);
end

% Background noise
[XBackground,ipSpec,f] = generate_colored_noise(spectralModel, noiseParams, nSamples, 1, 1);

visualize_dataset(XBackground, samplingFreq, 15, 'Bg noise');

% See if the spectral characteristics of the generated data produce the same spectral model
spectralModel2 = estimate_cross_spectrum(XBackground, [], dat.samplingFreq, physicalModel);

r=zeros(size(spectralModel.crossSpectrum,3),1);
for i=1:size(spectralModel.crossSpectrum,3)
	img1=squeeze(spectralModel.crossSpectrum(:,:,i));
	img2=squeeze(spectralModel2.crossSpectrum(:,:,i));
	co=corrcoef(img1(:),img2(:));
	r(i)=co(1,2);
end
plot(spectralModel.frequencies,r); ylabel('Correlation'); xlabel('Frequency')

poo0=reshape(spectralModel.crossSpectrum,[11*11 size(spectralModel.crossSpectrum,3)]);
poo2=reshape(spectralModel2.crossSpectrum,[11*11 size(spectralModel2.crossSpectrum,3)]);
poo0=poo0';
poo2=poo2';

real(corrcoef(real(poo0(:)),real(poo2(:))))

co=zeros(1,size(poo0,2));
for i=1:size(poo0,2)
	co(i)=corr(poo0(:,i),poo2(:,i));
end

if(0)

% Baseline drifts
XDrift1 = generate_colored_noise(spectralModel, noiseParams, nSamples, 150, 0);
XDrift2 = generate_colored_noise(spectralModel, noiseParams, nSamples, 300, 0);

visualize_dataset(XDrift1, samplingFreq, 15, 'Drift 1');
visualize_dataset(XDrift2, samplingFreq, 15, 'Drift 2');

% Todo: figure out good mixing weights per component, add the missing components
measuredSignal = XBackground + 0.0*XDrift1 + 0.0*XDrift2;

visualize_dataset(measuredSignal, samplingFreq, 15, 'Surface signal');

end
