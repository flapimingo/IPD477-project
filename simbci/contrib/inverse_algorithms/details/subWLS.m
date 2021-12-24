function [cortexeeg]= subWLS(scalpeeg, leadfield,Alpha)

% this is generalized (weighted) Least square. 

[m, n]=size(leadfield); % m is the number of electrodes, n is the number of sources*3
maxgrid3=n;
maxel=m;
maxgrid=n/3;

L=ones(m,1);
H=eye(m)-L*L'/(L'*L);  % the CAR matrix in sLORETA paper
scalpeeg=H*scalpeeg;
lft=(H*leadfield)';

P=leadfield;

cortexeeg=pinv(P'*P+Alpha*eye(n))*P'*scalpeeg;
%cortexeeg=pinv(P'*P)*P'*scalpeeg;

