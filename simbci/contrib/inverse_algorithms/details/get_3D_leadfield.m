function [ Leadfield_3D ] = get_3D_leadfield( Leadfield, NumberOriention, num_sources )
%GET_3D_LEADFIELD Get the 3D leadfield from 2D one
% LeadField : Original 2D Leadfield
% NumberOriention : Number of orientation for a single dipole (1 or 3)

assert(NumberOriention == 1 || NumberOriention == 3, 'Invalid number of orientation');

    Leadfield_3D = zeros(size(Leadfield,1), NumberOriention,...
                         size(Leadfield,2) / NumberOriention);
    for i=1:NumberOriention
        vectdata = i:NumberOriention:NumberOriention*num_sources;
        Leadfield_3D(:,i,:) = Leadfield(:,vectdata);
    end
end

