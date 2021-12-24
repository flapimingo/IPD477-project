function [X] = lcmv_inverse(G, Vmes, constrained, varargin)
%   LCMV_INVERSE   Compute inverse with LCMV beamformer
% G = Lead Field matrix
% Vmes = EEG measurments
% X -> TODO

options.foo = false;
[X, W] = lcmv_inverse_impl(Vmes, G, options);

end

function [X,W] = lcmv_inverse_impl(M,G,options)
%   LCMV_INVERSE   Compute inverse with LCMV beamformer
%       [X,W] = LCMV_INVERSE(M,G,OPTIONS)
%
%   Compute Inverse with Linearly Constrained Minimum Variance
%   beforming method.
%
%   w(:,i) = (G(:,i)'*C^-1*G(:,i))^(-1) G(:,i)' C^(-1)
%
%   and
%
%   X(i,:) =  w(:,i)' * M
%
%   C is the noise covariance matrix
%
%   C is set by the options structure : options.C
%
%   w(:,i) is the solution of :
%
%           min w' C w
%
%           s.t. w' G(:,i) = 1
%
%   Ref :
%
%   Vrba et al. Signal Processing in Magnetoencephalography. Methods (2001) vol. 25 (2) pp. 249-271
%
%   Note :
%
%   in case C is badely condition C can be replaced by C + lambda Id
%   where lambda is given as a pct of the biggest eigenvalue of C (options.pct)
%
%   Created by Alexandre Gramfort on 2008-12-03.
%   Copyright (c) 2007-2009 Alexandre Gramfort. All rights reserved.

% $Id: lcmv_inverse.m 139 2009-07-31 17:06:50Z gramfort $
% $LastChangedBy: gramfort $
% $LastChangedDate: 2009-07-31 19:06:50 +0200 (Ven, 31 jul 2009) $
% $Revision: 139 $

if nargin<3
    options.null = 0;
end

if ~isfield(options, 'C')
    options.C = eye(size(G,1));
end
C = options.C;

if ~isfield(options, 'pct')
    options.pct = 0;
end
pct = options.pct;

if isfield(options, 'null')
    options = rmfield(options,'null');
end

if pct > 0
    s = svd(C);
    lambda = pct/100 * s(1);
else
    lambda = 0;
end

Cinv = pinv(C + lambda*eye(size(C)));

W = sum(G .* (Cinv*G));
% W = sqrt(W); % Hack
W = 1 ./ W;
W(W == Inf) = 0;
W = spdiags(W(:),0,size(G,2),size(G,2))*G'*Cinv;

X = W*M;

end %  function
