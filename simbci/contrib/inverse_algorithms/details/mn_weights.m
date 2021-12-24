function [weights] = mn_weights(G,gam)
%   MN_WEIGHTS   Compute WMN weights
%       [WEIGHTS] = MN_WEIGHTS(G,GAM)
%
%   weights(i) = norm(G(:,i))^(1/gam)
%
%   where 'norm' stands for the Frobenius norm
%
%   gam = 1 : standard weights
%   gam = 2 : unbiased weights
%
%   Created by Alexandre Gramfort on 2008-06-30.
%   Copyright (c) 2007-2009 Alexandre Gramfort. All rights reserved.

% $Id: mn_weights.m 171 2009-10-22 13:23:06Z gramfort $
% $LastChangedBy: gramfort $
% $LastChangedDate: 2009-10-22 15:23:06 +0200 (jeu., 22 oct. 2009) $
% $Revision: 171 $

me = 'MN_WEIGHTS';

if nargin == 1
    gam = 2;
end

weights = sparse(1:size(G,2),1:size(G,2),sum(G.*G,1).^(1/(2*gam)));

end %  function
