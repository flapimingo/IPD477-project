function [ d ] = compute_point_mahalanobis_distance( x, distributionMean, distributionCovariance )
%COMPUTE_POINT_MAHALANOBIS_DISTANCE Computes the MD between a point and a
%distribution

assert(size(x, 1) == 1, 'Matrix input not supported. Use only one sample per call');

diff = x - distributionMean;
d = sqrt(diff * distributionCovariance * diff');

end

