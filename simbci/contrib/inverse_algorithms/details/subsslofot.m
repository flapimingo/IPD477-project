%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subsslofot -  estimate the source waveforms of the cortical sources 
%                using multi-point Standardized Shrinking Loreta FOCUSS
%
% function [cortexwave]= subsslofot(scalpeeg, leadfield, norme, looptime)
% 
%     cortexwave:   cortical source waveforms estimated by inverse algorithm  
%     scalpeeg:     EEG measured on scalp, a multi-channel time series
%     leadfield:    lead field matrix of the head model calculated by forward problem
%     scope:        The neighboring information, this matrix is generated using file findneighbor.m
%     norme:        estimate of noise norm at this time step (for Tikhonov regularization)
%     looptime:     number of iterations for sFOCUSS algorithm.  Increasing the looptime will 
%                   increase the focalization of the source map (i.e., reduce the extent of
%                   inverted source activity). In this implementation we allow the user to 
%                   specify the number of iterations instead of using an automatic stopping 
%                   criterion so that the focalization can be adjusted according to the need 
%                   need of the application. 
%    retain         the estimated source index.
%          
% Authors: Hesheng Liu & Paul Schimpf             
% Email: hesheng@wsu.edu , Schimpf@wsu.edu 
% Changes:  May 1, 2006:  Perform CAR on scalpeeg at this level so that the final time
%                         series needn't have CAR applied.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [cortexwave, retain] = subsslofot(scalpeeg,leadfield,scope,norme,looptime)

[channel, timelength]=size(scalpeeg);
[channel, maxgrid3]=size(leadfield);

% perform CAR here
ave = mean(scalpeeg) ;
for i=1:channel
    vm(i,:) = scalpeeg(i,:) - ave ;  
end 

% for each time sample, calculate a source map using single point SSLOFO
for i=1:timelength
    disp(['time step=', num2str(i)]) ;
    
    temp_result=substdshrink(vm(:,i),leadfield,scope,norme,looptime);  
    cortexeeg(i,:)=temp_result';
end

% re-define the source search space 
cortex_sum=sum(abs(cortexeeg),1);
node_retain=find(cortex_sum>0.1*max(cortex_sum));
leadfield_retain=leadfield(:,node_retain);

cortexwave=zeros(maxgrid3,timelength);
Wk=cortex_sum(1,node_retain);
Wk=Wk.^0.5;

% calculate the WMN (or WLS) inverse using the new source space.
for j=1:timelength
    [U,s,V] = csvd(leadfield_retain);
    Alp(j) = discrep4(U,s,V,scalpeeg(:,j),norme);
    % [x_del, AlpHan(j)] = discrep(U,s,V,scalpeeg(:,j),norme) ;
end
alpha=mean(Alp.^2);

for j=1:timelength
    if (length(node_retain)>channel) % underdetermined
        source(:,j)=subWMNt(scalpeeg(:,j),leadfield_retain,alpha,Wk',1);
    else  % overdetermined
        source(:,j)=subWLS(scalpeeg(:,j),leadfield_retain,max(alpha, 1e-5)); 
    end
    cortexwave(node_retain,j)=source(:,j);
end

retain=ceil(node_retain/3);
retain=unique(retain);
