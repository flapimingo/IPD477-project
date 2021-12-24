%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% substdshrink -   Single Point Standardized Shrinking Loreta FOCUSS(SSLOFO)
%
% function [CortexEEG]= substdshrink(ScalpEEG, LeadField, Scope, norme, LoopTime)
%
%     CortexEEG:    source current density estimated by inverse algorithm
%     ScalpEEG:     EEG measured on scalp, it's a time series
%     LeadField:    lead field matrix of the head model calculated by forward problem
%     Scope:        Cortical Neighbor information, this matrix is generated using file findneighbor.m
%     norme:        estimate of noise norm at this time step (for Tikhonov regularization)
%     LoopTime:     number of iteration for FOCUSS algorithm, usually 5~10 iterations is enough
%
% Authors:   Hesheng Liu, Paul Schimpf
% Email:     hesheng@wsu.edu , schimpf@wsu.edu
% Last Change:  March 10, 2006
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CortexEEG]= substdshrink(EEGSample, LeadField, Scope, norme, LoopTime)

%-------------------------------------------------------------
trunc = 0.20 ;     % voxels with magn less than 5% of max will be truncated during shrink operation
[m, n] = size(LeadField) ; % m is the number of electrodes, n is the number of sources*3
smallest_set = m ; % number of source sites beyond which shrinking process should not proceed.
%-------------------------------------------------------------
ncortex = n/3 ;
channel = length(EEGSample) ;

% initialize Tikhonov regularization parameter
[U,sm,V] = csvd(LeadField) ;
lambda = discrep4(U,sm,V,EEGSample,norme) ;
Alpha = lambda^2;

% initialize the low res cortex EEG by sLORETA
SrcEstimate = subsloreta(EEGSample,LeadField,Alpha);
SrcEstimate = SrcEstimate .* SrcEstimate ;  

%----------------------------------------------------------------
% refine the cortex EEG using shrinking standardized Focuss
P=zeros(n,m);

% this vector contains the index of voxels that will be retained after shrinking and smoothing
grid_reserve_index=1:n;
last_grid_reserve = grid_reserve_index ;
StopFlag=0 ;
last_Jt=SrcEstimate;

for loop=1:LoopTime
    
    LeadField_reserve=LeadField(:,grid_reserve_index);
    K=LeadField_reserve;
    
    % weighting matrix
    W = sqrt(SrcEstimate);
    
    % Tikhonov solution
    DW = diag(sparse(W)) ;
    KW = K*DW ;
    [U,sm,V] = csvd(KW) ;
    if(length(grid_reserve_index)>m & norme>0)   % if overdetermined and not noise free
       lambda = discrep4(U,sm,V,EEGSample,norme) ;
       Alpha = lambda^2 ;
    end
    
    T=DW*DW'*K'*pinv(K*DW*DW'*K'+ Alpha*eye(m));
    J=T*EEGSample;
    
    % normalize source estimate
    res = length(SrcEstimate)/3;
    Jt = zeros(1,res*3);
    for i=1:res
        Sj=T((i-1)*3+1:i*3,:)*K(:,(i-1)*3+1:i*3);
        Jl=J((i-1)*3+1:i*3);
        Jt((i-1)*3+1:i*3)=Jl'*pinv(Sj)*Jl;
    end
  
    % Here we check whether the last two solutions are essentially the same
    % (within 0.1 %) and quit if they are
    if (length(last_grid_reserve) == length(grid_reserve_index))
        if (sum(last_grid_reserve==grid_reserve_index) == length(grid_reserve_index)) 
            diff = norm( sqrt(Jt') - sqrt(last_Jt) ) / norm(sqrt(last_Jt)) ;
            % disp(['relative change = ', num2str(diff)]) ;
            if (diff < 0.001)
                disp(['stopping on iter ', num2str(loop), ' because solution unchanged']) ;
                break ;
            end 
            % myeps = 1e-9*norm(Jt)/m ;
            % if sum(Jt > myeps) < m
            %    disp(['solution is sparser than m on iter', num2str(loop)]) ;
            %    break ;
            % end 
        end
    end 
    
    SrcEstimate=Jt';
    last_Jt=Jt';
    last_grid_reserve = grid_reserve_index ;
    
    % do shrink and smooth if not the last iteration and stop flag is off
    if (loop<LoopTime & StopFlag==0)
        % truncate sources with small magnitude
        grid_reserve_index=grid_reserve_index(find(abs(SrcEstimate)>max(abs(SrcEstimate))*trunc));
        
        if length(grid_reserve_index) < smallest_set  
            StopFlag=1;
            grid_reserve_index = last_grid_reserve ;
            disp(['Source space stopped changing on iter ', num2str(loop), ' because reached smallest size']) ;
        else
            % Build a full n source vector
            % shrink by zeroing out small sources
            % rebuild nx1 matrix from the retained sources.
            SrcRebuilt=zeros(n,1);
            SrcRebuilt(grid_reserve_index,1)=SrcEstimate(find(abs(SrcEstimate)>max(abs(SrcEstimate))*trunc));

            % update SrcEstimate to match this new grid 
            % in case we don't finish the smoothing operation below
            SrcEstimate = SrcEstimate(find(abs(SrcEstimate)>max(abs(SrcEstimate))*trunc));
            
            % smoothing operation
            grid_spread=[];
            grid_spread=Scope(ceil(grid_reserve_index/3),2:end);  % include the neighbors
            [ro, co]=size(grid_spread);
            grid_spread=reshape(grid_spread,[1,ro*co]);
            grid_spread=unique(grid_spread);   % delete duplicate elements
            grid_spread(1)=[];  % the first element is zero, so delete it
            grid_spread=sort([grid_spread*3-2, grid_spread*3-1, grid_spread*3]);
            
            % spread the power on this new grid
            Src_spread=[];
            for j=1:size(grid_spread,2)
                p=grid_spread(j);
                aver=mean(SrcRebuilt(Scope(ceil(p/3),2:1+Scope(ceil(p/3),1))*3+mod(p,3)-3+(mod(p,3)==0)*3));
                num=Scope(ceil(p/3),1);
                Src_spread(j)=(aver*num+SrcRebuilt(p))/(num+1);  % note different in subshrinklofo
            end

            % if growing break out
            if length(Src_spread) >= (length(last_grid_reserve)+30)
                disp(['stopping on iter ', num2str(loop), 'because source space is growing']) ;
                break ;
            end
            
            SrcEstimate=Src_spread';
            grid_reserve_index=grid_spread ;
            
        end  % end shrink and smoothing
        
    end  % end if we should still be shrinking and smoothing
    
end  % end main iteration loop

% rebuild nx1 matrix using the retained sources.
SrcRebuilt=zeros(n,1);
SrcRebuilt(grid_reserve_index,1)=SrcEstimate(:);
temp_result=SrcRebuilt.^0.5;
ratio=norm(EEGSample)/norm(LeadField*temp_result);
result=temp_result*ratio;
CortexEEG=result;
