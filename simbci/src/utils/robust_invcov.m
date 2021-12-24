
% Computes robust inverse covariance
function [sigma,sigmaInv, E, D] = robust_invcov(X,tikhonov,shrink)

	tol=10e-10;

	diagCov = eye(size(X,2));

	% if we can't have a full cov rank (even in principle), force some regularization
	if(size(X,1)<size(X,2) && tikhonov == 0)
		tikhonov = 0.1*var(X(:));
	end

	sigma=cov(X);
	sigma=( shrink*diagCov+(1-shrink)*sigma + tikhonov*diagCov);	% regularization

	[E,D] = eig(sigma);

	Ddiag=diag(D);
	idxs = Ddiag>tol;
	Ddiag(idxs)=1./Ddiag(idxs);
	D(1:length(Ddiag)+1:end) = Ddiag;

	sigmaInv = E*D*E';
	% sigmaInv = inv(sigma);
