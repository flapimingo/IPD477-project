 
function featSpaces = md_select_features(feats, nClasses, trialsPerTask, howMany)

	assert(howMany >= 1);
	
	% Compute the distances between feats, 1 task against all others
	featSpaces = [];
	numFeats = size(feats, 2);

	for i=1:nClasses
		% Find the first feat to init the feat space
		distances = zeros(numFeats, 1);
		for j=1:numFeats
			taskFeats = feats(((i-1) * trialsPerTask + 1):(i * trialsPerTask), j);
			otherFeats = [feats(1:((i-1) * trialsPerTask), j)
						  feats((i * trialsPerTask + 1):end, j)];
			distances(j) = compute_distribution_mahalanobis_distance(taskFeats, otherFeats);
		end

		[foo, index] = max(distances);
		featSpace = [index];

		for j=1:(howMany-1)
			distances = zeros(numFeats, 1);
			for k=1:numFeats
				if(any(featSpace == k))
					continue;
				end
				tmpFeatSpace = [featSpace k];
				taskFeats = feats(((i-1) * trialsPerTask + 1):(i * trialsPerTask), tmpFeatSpace);
				otherFeats = [feats(1:((i-1) * trialsPerTask), tmpFeatSpace)
					feats((i * trialsPerTask + 1):end, tmpFeatSpace)];
				distances(k) = compute_distribution_mahalanobis_distance(taskFeats, otherFeats);
			end
			[foo, index] = max(distances);
			featSpace = [featSpace index];
			% FIXME Should we check that adding this feat *actually*
			% increases distance
		end
		featSpaces = [featSpaces featSpace];
	end
	
end

