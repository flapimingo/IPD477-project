function [U,s,V] = csvd(A) 
%CSVD Compact singular value decomposition. 
% 
% s = csvd(A) 
% [U,s,V] = csvd(A) 
% 
% Computes the compact form of the SVD of A: 
%    A = U*diag(s)*V', 
% where 
%    U  is  m-by-min(m,n) 
%    s  is  min(m,n)-by-1 
%    V  is  n-by-min(m,n). 
 
% Per Christian Hansen, IMM, 06/22/93. 
% P. Schimpf, simplified for SSLOFO, Jan 25, 2006

[m,n] = size(A); 
if (m >= n) 
  [U,s,V] = svd(full(A),0); s = diag(s); 
else 
  [V,s,U] = svd(full(A)',0); s = diag(s); 
end 
