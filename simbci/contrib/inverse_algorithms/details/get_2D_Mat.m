function [ Mat_2D ] = get_2D_Mat( Mat, NumberOriention )
%get_2D_Mat: Get the 3D leadfield from 2D one
% Mat : Original 3D Mat
% NumberOriention : Number of orientation for a single dipole (1 or 3)

assert(NumberOriention == 1 || NumberOriention == 3, 'Invalid number of orientation');
nbrSrc=size(Mat,2);
nbrtime = size(Mat,3);

    Mat_2D = zeros(size(Mat,2)* NumberOriention, nbrtime);
    for i=1:nbrSrc
        for j=1:NumberOriention
            datasrcJ(1,:) = Mat(j,i,:);
            Mat_2D((i-1)*3+j,:) = datasrcJ;
        end
    end
    
end

