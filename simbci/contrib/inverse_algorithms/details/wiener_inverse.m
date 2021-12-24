function [Ginv] = wiener_inverse(G,C,R,options)

% WIENER_INVERSE   Compute Wiener inverse filter
%
%   G : forward operator
%   C : Measurement correlation matrix
%   R : Source correlation matrix
%
%   Ginv = R * G' * inv(G * (R * G') + lambda * C);
%
%   SYNTAX
%       [W] = WIENER_INVERSE(A,C,R)
%
%   Created by Alexandre Gramfort on 2008-04-27.
%   Copyright (c) 2007-2009 Alexandre Gramfort. All rights reserved.
%

% $Id: wiener_inverse.m 124 2008-06-30 12:27:19Z agramfor $
% $LastChangedBy: agramfor $
% $LastChangedDate: 2008-06-30 14:27:19 +0200 (Lun, 30 jui 2008) $
% $Revision: 124 $

if nargin<4
    options.null = 0;
end

if ~isfield(options, 'pct')
    options.pct = 10;
end
pct = options.pct;

if ~isfield(options, 'lambda')
    if 1 % use SVD for lambda
        singular_values = svd(double(G * R * G'),'econ') * size(C,1) / trace(C);
        options.lambda = pct / 100 * singular_values(1);
    else % use trace for lambda
        options.lambda = pct / 100 * trace(G * R * G') / size(G,1) * size(C,1) / trace(C);
    end
end
lambda = options.lambda;

Ginv = mrdivide(R * G',G * (R * G') + lambda * C);
% Ginv = R * G' * inv(G * (R * G') + lambda * C);
