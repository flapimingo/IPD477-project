% Computes how good different projections in a
% given matrix 'cspModel' are in terms of the CSP objective function
% when evaluated in a one-vs-all fashion.
%
% Output : score [nProjections nClasses]
%
function score = csp_score(cspModel, X, sampleLabels)

u = unique(sampleLabels);

score = zeros(size(cspModel, 1), length(u));

S = cspModel * X';

for i=1:length(u)
	blockIn = S(:,sampleLabels==u(i));
	blockOut = S(:,sampleLabels~=u(i));

	score(:,i) = ( var(blockIn,[],2) ./ var(blockOut,[],2) )';
end


