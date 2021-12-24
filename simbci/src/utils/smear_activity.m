
%
% This will spread activity of selected sources to nearby dipoles
%
function Snew = smear_activity(S, sources, physicalModel, spread)

	if(nargin<4)
		spread = 0.001;
	end
	if(spread <= 0)
		Snew = S;
		return;
	end

	sourcePos = physicalModel.sourcePos;

	% spread activity of each source to nearby sources using
	% Gaussian weighting
	Snew = zeros(size(S));
	for srcIdx = sources
		[~,distances] = find_closest_dipole_from(sourcePos, sourcePos(srcIdx,:));
		weights = exp(-distances / spread);
		Stmp = repmat(weights', [size(S,1) 1]) .* repmat(S(:,srcIdx), [1 size(S,2)]);

		% Mix linearly, as the Gaussian masks may overlap
		Snew = Snew + Stmp;
	end
