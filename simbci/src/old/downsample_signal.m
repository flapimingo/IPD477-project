function [ SDownsampled ] = downsample_signal(S, samplingFreq, newFreq )
%DOWNSAMPLE_SIGNAL Downsamples the signal to newFreq

assert(samplingFreq >= newFreq, 'Can not downsample to higher frequency');
assert(mod(samplingFreq, newFreq) == 0, 'Only supporting downsample to multiple freqs')

downsampleSteps = samplingFreq / newFreq; % number of elements to skip in the signal

SDownsampled = S(1:downsampleSteps:end);

end

