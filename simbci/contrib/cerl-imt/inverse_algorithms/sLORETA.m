
% sLoreta inverse
function XsLO = sLORETAmod(G, Vmes, constrainedOrientation, varargin)%, varargin
% @author Axelle Pillain

%%Inverse EEG : calc des sources J^p pb de la forme M=GX+E, M = mesures = Vmes,
%G = mod�le de propagation, X = J^p <=> sources recherch�es.

%utilisation de donn�es statistiques.
%sigma = covariance
%on suppose dans un premier temps sigmaX = Id (pas de donn�es apriori sur
%les sources).
%Estimation � l'aide de la co-variance spatiale
%Doc = R.D.Pascual-Marqui, sLORETA, technical details

m = size(G,1);
%l = size(G,2);
ave = eye(m)-ones(m,m)/m;
G = ave*G; %moyenne nulle idem pour leadfield matrix
Vmes = ave*Vmes;
% 
[U,S,V] = svd(G);
lambda = 0.01*S(1,1)^2;

%estimation de la variance des sources:
% size(G')
% size (lambda*ave)
% size(G*G'+lambda*ave)
% size(G)
% Sj = (G'/(G*G'+lambda*eye(m)))*G;
Sj = (G'/(G*G'+lambda*eye(m)))*G;
Xest = G'*((G*G'+lambda*eye(m))\Vmes);%MinimumNorm(G,Vmes,lambda)
%calcul de Xest sLORETA:
if (~constrainedOrientation)
	XsLO = zeros(size(Xest,1)/3,size(Xest,2));
	for i = 1:3: size(Xest,1)
		% XsLO((i+2)/3,:) = diag((Xest(i:i+2,:)'/(Sj(i:i+2,i:i+2)))*Xest(i:i+2,:));
		XsLO((i+2)/3,:) = sum( (Xest(i:i+2,:)'/Sj(i:i+2,i:i+2)) .* Xest(i:i+2,:)', 2);
    end    
else
	XsLO = zeros(size(Xest,1),size(Xest,2));
	for i = 1:size(Xest,1)
		% XsLO((i+2)/3,:) = diag((Xest(i:i+2,:)'/(Sj(i:i+2,i:i+2)))*Xest(i:i+2,:));
		XsLO(i,:) = sum( (Xest(i,:)'/Sj(i,i)) .* Xest(i,:)', 2);
	end
end

