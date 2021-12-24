%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subsloreta -  estimate the current density inside the brain volume
%                  using the EEG measured on the scalp, the inverse method 
%                  is Standardized Loreta
%
% function [CortexEEG]= subsloreta(ScalpEEG, LeadField,Alpha)
% 
%     CortexEEG:   source current density estimated by inverse algorithm  
%     ScalpEEG:    EEG measured on scalp, it's a time series
%     LeadField:   lead field matrix of the head model calculated by forward prob
%     Alpha:       Tikhonov regularization parameter for sLORETA 
%
% Ref: R.D.Pascual-Marqui,  Standardized low resolution brain electromagnetic 
%      tomography (sLORETA):technical details, Methods&Findings in clinical and 
%      experimental pharmacology, 2002, 24D:5-12
%  
% Authors: Hesheng Liu & Paul Schimpf             
% Email: hesheng@wsu.edu , Schimpf@wsu.edu 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [CortexEEG]= subsloreta(ScalpEEG,LeadField,Alpha)

% m is the number of electrodes, n is the number of sources*3
[m, n]=size(LeadField); 
ncortex=n/3;

[channel, timelength]=size(ScalpEEG);

%-------------------------------------------------------------

for time=1:timelength
    % calculate the loreta inversion  
    EEGSample=ScalpEEG(:,time); %1*m
    
    L=ones(m,1);
    H=eye(m)-L*L'/(L'*L);%the CAR matrix in sLORETA paper
    
    EEGSample=H*EEGSample;
    K=H*LeadField;
    
    % pseudo-inverse
    T=K'*pinv(K*K'+Alpha*H);
    J=T*EEGSample;
    
    % rmatrix=T*K;
    
    for i=1:ncortex  
        Jl=J((i-1)*3+1:i*3);
        Sj=T((i-1)*3+1:i*3,:)*K(:,(i-1)*3+1:i*3);
        %Sj=rmatrix((i-1)*3+1:i*3,(i-1)*3+1:i*3);
        Jt((i-1)*3+1:i*3)=Jl'*inv(Sj)*Jl;
    end
    
    % scale correction 
    temp_result=abs(Jt').^0.5;
    
    ratio=norm(EEGSample)/norm(LeadField*temp_result);
    result=temp_result*ratio;
    CortexEEG(:,time)=result;

end
