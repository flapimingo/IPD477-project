function X = wmn_inverse(G, Vres, constrained, varargin)
% WMN_INVERSE   Compute weighted minimum norm inverse solution
% Inverse source using DSPM algorithm
% G = Lead Field matrix
% Vmes = EEG measurments
% X -> X / Vmes = G * X

options.verbose = false;

[X,Ginv,lambda] = wmn_inverse_impl(Vres,G,options);

end


function [X,Ginv,lambda] = wmn_inverse_impl(M,G,options)

% WMN_INVERSE   Compute weighted minimum norm inverse solution
%
%   M = G * X
%   M : measurements
%   X : sources
%   G : leadfield or gain matrix
%
%   Problem :
%
%       X = argmin | M - G*X |^2 + lambda | W*X |^2
%               X
%       where W is a square matrix.
%
%   It can be solved using mn_inverse.m by noticing that
%
%       X = W^(-1) * mn_inverse(M,G*W)
%
%   SYNTAX
%       [X,GINV,LAMBDA] = WMN_INVERSE(M,G,options)
%
%   Created by Alexandre Gramfort on 2007-10-22.
%   Copyright (c) 2007-2009 Alexandre Gramfort. All rights reserved.

% $Id: wmn_inverse.m 171 2009-10-22 13:23:06Z gramfort $
% $LastChangedBy: gramfort $
% $LastChangedDate: 2009-10-22 15:23:06 +0200 (jeu., 22 oct. 2009) $
% $Revision: 171 $

if nargin<3
    options.null = 0;
end

if ~isfield(options, 'weights_exponent')
    % options.weights_exponent = 1; % standard
    options.weights_exponent = 2; % unbiased : thomas
end
weights_exponent = options.weights_exponent;

if ~isfield(options, 'W')
    options.W = mn_weights(G,weights_exponent);
end
W = options.W;

if ~isfield(options, 'pct')
    options.pct = 5;
end
pct = options.pct;

if ~isfield(options, 'verbose')
    options.verbose = true;
end
verbose = options.verbose;

if ~isfield(options, 'use_mn')
    options.use_mn = false;
end
use_mn = options.use_mn;

if isfield(options, 'null')
    options = rmfield(options,'null');
end

if size(W) == [1,1]
    W = W*speye(size(G,2));
end

% W is diagonal
isdiag =  (size(W,1)==size(W,2)) && ~(numel(find(W-spdiags(diag(W),0,size(W,1),size(W,1)))) > 0);

if ~isdiag % do not use mn_inverse when W is not diagonal
    use_mn = false;
end

if use_mn

    if ~isdiag
        % W_inv = inv(W);
        GW_inv = mrdivide(G,W);
    else
        D = diag(W);
        D_inv = 1./D;
        D_inv(D == 0) = 0;
        W_inv = sparse(1:size(G,2),1:size(G,2),D_inv);
        GW_inv = G*W_inv;
    end

    [tmp,Ginv,lambda] = mn_inverse(M,GW_inv,options);
    Ginv = W \ Ginv;
    X = Ginv * M;

else

    Ginv = mrdivide(G,W'*W)*G'; % compute G * (W*W')^-1 * G';
    S = svd(Ginv,0);
    S = diag(S);
    lambda = sqrt(S(1))*pct/100;
    Ginv = mrdivide(G',Ginv+lambda^2*eye(size(G,1)));
    Ginv = (W'*W) \ Ginv;

    X = Ginv*M;

    if verbose
        disp(['Lambda : ',num2str(lambda),' ( ',num2str(lambda/sqrt(S(1))*100),' pct)']);
    end

end
end
