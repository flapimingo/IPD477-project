function [sourceIdxs,d] = find_neighbours(ref, howMany, dipolesBetweenSources, physicalModel, delta)
% Find some sources close to source with index 'ref'
% Note that the search happens to a specific direction in the volume
%
% ref   - the source index to start from
% delta - can be used to select the direction of traversal
%
	assert(howMany>=1);

	if(nargin<5)
		% default direction to proceed to is +y
		delta = [0,1,0];
	end
	
	assert(length(delta)==3, 'Need 3 coordinates in delta');
	
	% Here we remove the duplicate sources for simplicity;
	% this is essentially the same as doing this search with a 'constrained' leadfield
	if(physicalModel.constrainedOrientation) 
		sourcePos = physicalModel.sourcePos;
	else
		sourcePos = physicalModel.sourcePos(1:3:end,:);		
		ref = floor( (ref(1)-1)/3 ) + 1;
	end
	
	numSources = size(sourcePos,1);
	sourceIdxs = zeros(howMany,1);

	% Start with the ref
	sourceIdxs(1) = ref;
	sourcePosPrev = sourcePos(ref,:);		
	sourcePos(ref,:) = Inf; % Never select it again
	
	% d	is distance of the closest source to the ref, it approximates the scale
	d = sqrt(min(sum( (sourcePos - repmat(sourcePosPrev,  [numSources 1])).^2, 2)));
	
	% make the step vector relative to the scale
	delta = dipolesBetweenSources .* delta .* d;
	
	for i=2:howMany
		neighbourIdx = find_closest_dipole_from( sourcePos, sourcePosPrev + delta, physicalModel.constrainedOrientation );
		neighbourIdx = neighbourIdx(1); % In this case we're always operating with 1dim/src 
        assert(~(any(sourcePos(neighbourIdx,:) == Inf)), 'Same source selected twice');
		
		sourcePosPrev = sourcePos(neighbourIdx,:);
		sourcePos(neighbourIdx,:) = Inf;	% make sure its never selected again
		
		sourceIdxs(i) = neighbourIdx;
	end
	
	if(~physicalModel.constrainedOrientation) 
		% replicate each index 3 times and add 1-3 to get 3 consequtive indexes per dipole. 
		% multiply by 3 to get correct indexes from 'constrained' -> 'nonconstrained'
		v = repmat(1:howMany,[3 1]); v = v(:);
		sourceIdxs = 3*(sourceIdxs(v)-1) + repmat((1:3)',[howMany 1]);
	end
	
	% assert(length(unique(sources)) == length(sources), 'all sources are not unique, try decreasing dipolesBetweenSources');
	
end

