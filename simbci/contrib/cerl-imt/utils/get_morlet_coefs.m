function [ PSI ] = get_morlet_coefs( time, freqs, FWHM, fc )
%GET_MORLET_COEFS returns the coeficients of the morelet wavelets
%   /!\ 'time' must be centered around 0!

Sc = FWHM / sqrt(8*log(2)); % Gaussian kernel at central frequency

% Computing the wavelet distribution
[T, F] = meshgrid(time, freqs);
St = Sc * fc ./ F;
PSI = (1 ./ sqrt(sqrt(pi) * St)) .* exp(-T .* T ./ (2 * St .* St)) .* ...
	exp(2 * pi * 1j * F .* T); % Using F instead of fc, seems to be a typo in the paper!

end

