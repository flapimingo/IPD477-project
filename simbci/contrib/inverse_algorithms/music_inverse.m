function SourceCoefs = music_inverse(G, Vmes, orientation_forced, varargin)
% Source localization using MUSIC algo
% SourceCoefs = ??? TODO
% G = Lead Field matrix
% Vmes = EEG measurments
% orientation_forced = bool to decide wether each dipoles has one component
% (true) or three (false)
 k = 2;
 
 options.oriented = ~orientation_forced;
 options.k = k; % Might want to experiment with different values of k
 
 SourceCoefs = zeros(size(Vmes, 2),size(G, 2));

 for t=1:size(SourceCoefs, 1)
    SourceCoefs(t,:) = music_inverse_embal(Vmes(:, t), G, options);
 end

end

function [X] = music_inverse_embal(M,G,options)

% MUSIC_INVERSE   Inverse with the MUSIC algorithm
%
%   Inverse with the MUSIC algorithm
%
%   options.k = dimension of data space
%   NOTE from Lyes: it seems the option interpretation was inverted in the
%                   original doc.
%   options.oriented = false     : if G is orientation contrained
%                      or
%                      true    : if G = Gxyz and best orientation is obtained at each point
%
%   SYNTAX
%       [X] = MUSIC_INVERSE(M,G,OPTIONS)
%
%
%
%   Created by Alexandre Gramfort on 2008-01-22.
%   Copyright (c) 2007-2009 Alexandre Gramfort. All rights reserved.

% $Id: music_inverse.m 171 2009-10-22 13:23:06Z gramfort $
% $LastChangedBy: gramfort $
% $LastChangedDate: 2009-10-22 15:23:06 +0200 (jeu., 22 oct. 2009) $
% $Revision: 171 $

me = 'MUSIC_INVERSE';

if nargin<3
    options.null = 0;
end

if ~isfield(options, 'k')
    options.k = 10;
end
k = options.k;

if ~isfield(options, 'display')
    options.display = false;
end
display = options.display;

if ~isfield(options, 'oriented')
    options.oriented = true;
end

oriented = options.oriented;

% MUSIC like comparison
[U,S,V] = svd(M,'econ');
S = diag(S);

k = min(k,size(U,2));
%disp(['    MUSIC Data space dimension : ',num2str(k)])
Usig = U(:,1:k);
Psig = Usig*Usig';
Pnoi = eye(size(M,1))-Psig;

if oriented
    % Normalize columns of G
    norms = sqrt(sum(G.^2));
    G = G ./ repmat(norms,size(G,1),1);
    G(isnan(G)) = 0;
    X = Pnoi*G;
    X = sum(X.^2)';
else
    npts = size(G,2) / 3;
    for i=1:npts
        %progressbar(i,npts);
        sidx = 3*(i-1)+1;
        [U,Sg,V] = svd(G(:,sidx:sidx+2),'econ');
        X(i) = min(eig(U(:,1:2)' * Pnoi * U(:,1:2))); % Gxyz(i) is rank 2
    end
end

X = 1 - X;

if display
    figure
    plot(S(1:min(size(S,1),10)))
    line([k k],get(gca,'ylim'),'Color','k')
end
end
