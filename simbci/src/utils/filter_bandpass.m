
function dat = filter_bandpass(dat, freq, lowLimit, highLimit, filterOrder)
% input dat must be in [nSamples,nChannels] order
	if(nargin<5)
		filterOrder = 2;
	end

	assert(size(dat,1)>size(dat,2), 'More channels than samples. Input matrix is probably oriented wrong.');

	[filtB,filtA] = butter(filterOrder, [lowLimit highLimit]/(freq/2));
	dat = filter(filtB, filtA, dat);

