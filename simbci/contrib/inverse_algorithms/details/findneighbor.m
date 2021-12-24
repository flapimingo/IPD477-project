%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [scope] = findneighbor(roi, thresh, scale)
% For every location (column) in roi (3 x n), find neighbors that fall within 
% "thresh" (probably mm) of it.  Vector scale is a 3x1 vector of scale factors for the 
% real coordinates in roi. For the file oddroi.mat, the scale factor is [2 2 3.2].
% The neighbors are returned in scope.  Each row of scope
% contains the neighbors of the corresponding location in roi, and the first
% entry in that row gives the number of neighbors.  Thus there are "ncortex" rows
% in scope, but the number of columns is variable.
%
% Hesheng Liu           email: hesheng@wsu.edu
% P. Schimpf  03-23-04  Converted to a function with some parameters
%                       Changed && to & in average value test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%function [scope] = findneighbor(roi, thresh, scale)
function [scope] = findneighbor(roi, thresh)

% thresh = distance to be in the neighbouring region.
[~, ncortex] = size(roi) ;
%factor=diag(scale); 
%roi=factor*roi;


%-----------------------------------
for j=1:ncortex % for every fixed point in the cortex
    
    if (mod(j,100)==0) 
%         disp(num2str(j)) ;
    end ;
     
    zopenum=1;
%     x1=[0 0 0];
%     x2=[0 0 0];
    for k=1:ncortex
        % record the nodes drop within the scope
        if (k~=j && norm(roi(:,j)-roi(:,k))<thresh) 
            zopenum=zopenum+1;
            scope(j,zopenum)=k;
        end
    end
    scope(j,1)=zopenum-1;
end
% save scope scope
