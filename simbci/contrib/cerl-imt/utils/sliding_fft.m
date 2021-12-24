function [ spectrum, number_ffts_per_channel ] = sliding_fft( signals, window_duration, window_step )
%UNTITLED Computes an FFT every window_step samples on the latest windows
%duration samples of data
% n.b. takes as input data which is oriented differently than usual in this platform,
% i.e. [channels x samples]

[numChannels, numSamples] = size(signals);

number_freq_bins = window_duration / 2;
number_ffts_per_channel = floor(  (numSamples - window_duration) / window_step );

spectrum = zeros(numChannels, number_freq_bins * number_ffts_per_channel);

for i=1:number_ffts_per_channel
    ffts =  fft(signals(:,(i-1) * window_step + 1: (i-1) * window_step + window_duration), [], 2);
    spectrum(:, (i-1) * number_freq_bins + 1 : i * number_freq_bins) = ffts(:, 2:number_freq_bins+1);
end

end
