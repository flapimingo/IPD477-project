function [ powers ] = current_dipoles_to_dipole_power( currents, combine_dipole_directions)
%UNTITLED2 Converts a matrix of (dipole currents x time) into a matrix (dipole power x time).
%If (combine_dipole_directions == true) the 3 adjacent dipoles are combined into a single one.

powers = currents .^ 2;
if(combine_dipole_directions)
	assert(rem(size(powers,1),3)==0, 'Number of dipoles not divisible by 3');
	% Might be faster with reshape, but more robust+understandable like this.
	powers = powers(1:3:end,:) + powers(2:3:end,:) + powers(3:3:end,:);
end

end

