function [weights] = whitening_weights_dspm(W,C)

% WHITENING_WEIGHTS_DSPM   Compute spatial whitening weights for dSPM
%
%   W : Wiener filter
%   C : measurement correlation matrix
%
%   SYNTAX
%       [WEIGHTS] = WHITENING_WEIGHTS_DSPM(W,C)
% 
%   Solution is given by :
%
%       weights = sqrt(diag(W*C*W'))
%

%
%   Created by Alexandre Gramfort on 2008-04-27.
%   Copyright (c) 2007-2009 Alexandre Gramfort. All rights reserved.
%

% $Id: whitening_weights_dspm.m 141 2009-09-02 14:10:12Z gramfort $
% $LastChangedBy: gramfort $
% $LastChangedDate: 2009-09-02 16:10:12 +0200 (mer., 02 sept. 2009) $
% $Revision: 141 $

dim = size(W,1);
weights = sqrt(sum(W.*(W*C),2));
weights = 1./weights;
weights(isnan(weights)) = 0;
weights = spdiags(weights,0,dim,dim);
