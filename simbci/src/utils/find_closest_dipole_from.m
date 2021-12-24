% Finds the closest dipole from coords = [x, y, z]'
%
% Returns distances of all dipoles in the second argument
%
function [ dipole, distances ] = find_closest_dipole_from( sourcePos, coords, constrainedOrientation )
	distances = sum( (sourcePos - repmat(coords, [size(sourcePos,1) 1])).^2, 2);

	[~, dipole] = min(distances);

	if(~constrainedOrientation)
		dipole = [dipole,dipole+1,dipole+2];
	end
end

