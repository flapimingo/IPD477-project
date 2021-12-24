function [ TFR ] = compute_morlet_TFR( S, PSI )
%COMPUTE_MORLET_TFR Do the actual computation of the TFR of S given PSI coefs

% Use the signal bellow to debug the wavelets: you should see 3
% perfect segments.
% s = [sin(12*2*pi*t(1:end/3)) sin(10*2*pi*t((end/3+1):(2*end/3))) sin(8*2*pi*t((2*end/3+1):end))];
TFR = zeros(size(PSI));
for i=1:size(PSI, 1)
	TFR(i,:) = conv(S, PSI(i,:), 'same');
end

end

