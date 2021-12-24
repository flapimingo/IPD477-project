function [X] = mn_inverse(G, Vmes, constrained, varargin)
% MN_INVERSE   Compute minimum norm inverse solution
% G = Lead Field matrix
% Vmes = EEG measurments
% X -> X / Vmes = G * X

options.foo = false;
[X, Ginv, lambda] = mn_inverse_impl(Vmes,G,options);

end

function [X,Ginv,lambda] = mn_inverse_impl(M,G,options)

% MN_INVERSE   Compute minimum norm inverse solution
%
%   M = G * X
%   M : measurements
%   X : sources
%   G : leadfield or gain matrix
%
%   Problem :
%
%       X = argmin |M - G*X|_F^2 + lambda * | X |_F^2
%
%   SYNTAX
%       [X,GINV,LAMBDA] = MN_INVERSE(M,G,options)
%
%
%   Created by Alexandre Gramfort on 2007-10-22.
%   Copyright (c) 2007-2009 Alexandre Gramfort. All rights reserved.
%
% $Id: mn_inverse.m 171 2009-10-22 13:23:06Z gramfort $
% $LastChangedBy: gramfort $
% $LastChangedDate: 2009-10-22 15:23:06 +0200 (jeu., 22 oct. 2009) $
% $Revision: 171 $

me = 'MN_INVERSE';

if nargin<3
    options.null = 0;
end

if ~isfield(options, 'verbose')
    options.verbose = true;
end
verbose = options.verbose;

if ~isfield(options, 'U') & ~isfield(options, 'S') & ~isfield(options, 'V')
    GGt = G*transpose(G);
    [options.U,S,options.V] = svd(GGt);
    options.S = diag(S);
end
U = options.U;
S = options.S;
V = options.V;

if isfield(options, 'use_gcv') & options.use_gcv & isfield(options, 'use_lcurve') & options.use_lcurve
    error('Cannot set both options.use_gcv and options.use_lcurve to true !')
end

% Get Lambda via Generalized cross validation
if ~isfield(options, 'use_gcv')
    options.use_gcv = false;
end
use_gcv = options.use_gcv;

if use_gcv
    if verbose
        disp('Setting lambda with GCV');
    end
    options.lambda = gcv(U,sqrt(S),M,'tikh',verbose);
end

% Get Lambda via L-Curve
if ~isfield(options, 'use_lcurve')
    options.use_lcurve = false;
end
use_lcurve = options.use_lcurve;

if use_lcurve
    disp('Setting lambda with L-Curve');
    options.lambda = l_curve(U,sqrt(S),M,options);
end

if isfield(options, 'pct') & isfield(options, 'lambda')
    error('Cannot set both options.pct and options.lambda !')
end

eps = 1e-7;
tol = size(U,1) * S(1) * eps;
reg_rank = sum(S > tol);

if ~isfield(options,'lambda')
    if ~isfield(options, 'pct')
        options.pct = 10; % 10 percent by default
    end
    pct = options.pct;

    if nargin == 0
        eval(['help ',lower(me)])
        options = rmfield(options,'null')
        return
    end

    options.lambda = sqrt(S(1))*pct/100; % using values already squared with Tikhonov percentage
end

lambda = options.lambda;

Sinv = 1../(S(1:reg_rank)+lambda^2); % filtered inverse

if verbose
    disp(['Lambda : ',num2str(lambda),' ( ',num2str(lambda/sqrt(S(1))*100),' pct)']);
end

Ginv = transpose(G)*V(:,1:reg_rank)*((spdiags(Sinv,0,reg_rank,reg_rank)*U(:,1:reg_rank)'));
X = Ginv*M; % Estimated Data

end %  function
