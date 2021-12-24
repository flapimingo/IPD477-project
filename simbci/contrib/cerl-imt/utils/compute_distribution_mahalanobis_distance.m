function [ d ] = compute_distribution_mahalanobis_distance( featSpace1, featSpace2 )
%COMPUTE_MAHALANOBIS_DISTANCE Computes MD between two distributions

diff = mean(featSpace1) - mean(featSpace2);
covariance1 = cov(featSpace1);
covariance2 = cov(featSpace2);
n1 = size(featSpace1, 1);
n2 = size(featSpace2, 1);
n = n1 + n2;

% prevent potential cov+scalar summation below that'd make pooled cov more
% singular. This case can happen if either featspace has just 1 example.
if(size(covariance1,1)<size(covariance2,1))
	covariance1 = 0;
end
if(size(covariance2,1)<size(covariance1,1))
	covariance2 = 0;
end

pooledCov = n1 / n * covariance1 + n2 / n * covariance2;

% Adhoc regularization: If co is invertible, result is equal to inv.
% If not, we get an approximation...
invCo = pinv(pooledCov);
	
% d = sqrt(diff * (pooledCov \ diff'));		% not regularized
d = sqrt(diff * invCo * diff');				% regularized if co singular

end
