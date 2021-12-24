function lambda = discrep4(U,s,V,obs,norme) 
% DISCREP Discrepancy principle criterion for choosing the reg. parameter. 
% lambda = discrep4(U,s,V,obs,norme) 
% 
% Requires the compact SVD of L passed in as  U, s, and V
%
% P. Schimpf, Dec 15, 2003
% modified from Per Christian Hansen's discrep, IMM, 12/29/97.
 
% Initialization. 
[a,b] = size(U) ; 
[c,d] = size(V) ;
m = max(a,b) ;
n = max(c,d) ;
p = min(n,m) ;

resid2 = zeros(p,1); 
src = zeros(n,1);
srcproj = V'*src; 
 
% Compute residual norms corresponding to TSVD/TGSVD. 
obsproj = U'*obs; 
resid_0 = norm(obs - U*obsproj) ;
resid2(p) = resid_0^2 ;
for i=p:-1:2        
  resid2(i-1) = resid2(i) + (obsproj(i) - s(i)*srcproj(i))^2 ; 
end 
 
% Check input. 
if (norme<0) 
  lambda = -1 ;
  error('Illegal noise norm')  ;
end 
if (norme < resid_0) 
  % warning('norme < smallest possible residual, so increasing it') 
  norme = resid_0 ;
end 
 
% find the SVD truncation that would leave residual = norme
[dummy,kmin] = min(abs(resid2 - norme^2)); 
% kmin = max(1, kmin-1) ;
% lambda = s(kmin); 
lambda = newton(s(kmin),norme,s,obsproj(1:p),srcproj,resid_0); 
if (lambda==-1 | lambda==inf) 
   lambda = s(kmin) ;
end ;
