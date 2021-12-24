function X = dspm_inverse(G, Vmes, constrained, varargin)
% Inverse source using DSPM algorithm
% G = Lead Field matrix
% Vmes = EEG measurments
% X -> X / Vmes = G * X

options.foo = false;

[X, Ginv] = dspm_inverse_impl(Vmes, G, options);

end

function [X,Ginv] = dspm_inverse_impl(M,G,options)

% DSPM_INVERSE   Compute dSPM inverse
%
%   M = G * X
%   M : measurements
%   X : sources
%   G : leadfield or gain matrix
%
%   Problem :
%
%       X = argmin || C^(-1/2)*(M - G*X) ||_F^2 + lambda * || R^(-1/2) * X ||_F^2
%
%   and renormalize to get a F-distributed function
%
%   SYNTAX
%       [X,GINV] = DSPM_INVERSE(M,G,OPTIONS)
%
%
%   Created by Alexandre Gramfort on 2008-04-27.
%   Copyright (c) 2007-2009 Alexandre Gramfort. All rights reserved.
%

% $Id: dspm_inverse.m 171 2009-10-22 13:23:06Z gramfort $
% $LastChangedBy: gramfort $
% $LastChangedDate: 2009-10-22 15:23:06 +0200 (jeu., 22 oct. 2009) $
% $Revision: 171 $

if nargin<3
    options.null = 0;
end

if ~isfield(options, 'C')
    options.C = speye(size(G,1));
end
C = options.C;

if ~isfield(options, 'R')
    options.R = speye(size(G,2));
end
R = options.R;

Ginv = wiener_inverse(G,C,R,options);

weights = whitening_weights_dspm(Ginv,C);

Ginv = weights*Ginv;

X = Ginv*M; %Estimated Data

return
end
