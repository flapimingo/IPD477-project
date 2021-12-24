function [ sources, layer ] = where_heuristic( physicalModel, varargin )
% Given a head model, heuristically guesses dipole indexes corresponding to positions
%
% Note if the leadfield is nonconstrained (has 3dof or 3src per dipole), this will
% return 3 indexes for each source.
% 
% layer: 1==volume, 2==surface
%

	% Parse inputs
	p = inputParser;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p,'position',             'volume', @ischar);
	addParameter(p,'dipolesBetweenSources', 10,      @isint);
	addParameter(p,'howMany',                1,      @isint);

	p.parse(varargin{:});

	params = p.Results;

	%%%%%%%%%%%%%%

	layer = 1; % default is volume
	
	sPos = physicalModel.sourcePos;

	if(strcmp(params.position,'leftMC'))
		% One source on the left, one on the right
		assert(params.howMany==1);
		% mx,my,mz=skull center : for convenience
		mx = (max(sPos(:,1))+min(sPos(:,1)))/2;
		my = (max(sPos(:,2))+min(sPos(:,2)))/2;
		mz = (max(sPos(:,3))+min(sPos(:,3)))/2;
		leftCenter0 =  [(mx+min(sPos(:,1)))/2,my,max(sPos(:,3))/2];
		sources = find_closest_dipole_from( sPos, leftCenter0, physicalModel.constrainedOrientation );
	elseif(strcmp(params.position,'rightMC'))
		% One source on the left, one on the right
		assert(params.howMany==1);
		% mx,my,mz=skull center : for convenience
		mx = (max(sPos(:,1))+min(sPos(:,1)))/2;
		my = (max(sPos(:,2))+min(sPos(:,2)))/2;
		mz = (max(sPos(:,3))+min(sPos(:,3)))/2;
		rightCenter0 = [(mx+max(sPos(:,1)))/2,my,max(sPos(:,3))/2];
		sources = find_closest_dipole_from( sPos, rightCenter0, physicalModel.constrainedOrientation  );
	elseif(strcmp(params.position,'leftAndRight'))
		% One source on the left, one on the right
		assert(params.howMany==2);
		% mx,my,mz=skull center : for convenience
		mx = (max(sPos(:,1))+min(sPos(:,1)))/2;
		my = (max(sPos(:,2))+min(sPos(:,2)))/2;
		mz = (max(sPos(:,3))+min(sPos(:,3)))/2;
		leftCenter0 =  [(mx+min(sPos(:,1)))/2,my,max(sPos(:,3))/2];
		rightCenter0 = [(mx+max(sPos(:,1)))/2,my,max(sPos(:,3))/2];
		leftCenter = find_closest_dipole_from( sPos, leftCenter0, physicalModel.constrainedOrientation );
		rightCenter = find_closest_dipole_from( sPos, rightCenter0, physicalModel.constrainedOrientation  );

		sources = [leftCenter,rightCenter];		
	elseif(strcmp(params.position,'leftCluster'))
		% Starting from a source on the left, select a bunch of neighbours
		centers = mean(sPos);
		offsetX = (min(sPos(:,1)) - centers(1)) / 2; % halfway between center and edge
		startCoords0 =  [centers(1)+offsetX,centers(2),centers(3)];
		startSource = find_closest_dipole_from( sPos, startCoords0, physicalModel.constrainedOrientation );

		sources = find_neighbours(startSource, params.howMany, params.dipolesBetweenSources, physicalModel);
	elseif(strcmp(params.position,'rightCluster'))
		% Starting from a source on the right, select a bunch of neighbours
		centers = mean(sPos);
		offsetX = (max(sPos(:,1)) - centers(1)) / 2; % halfway between center and edge
		startCoords0 =  [centers(1)+offsetX,centers(2),centers(3)];
		startSource = find_closest_dipole_from( sPos, startCoords0, physicalModel.constrainedOrientation );

		sources = find_neighbours(startSource, params.howMany, params.dipolesBetweenSources, physicalModel);
	elseif(strcmp(params.position,'eyes'))
		mx = (max(sPos(:,1))+min(sPos(:,1)))/2;
		mz = (max(sPos(:,3))+min(sPos(:,3)))/2;
		leftEye0 =  [(mx+min(sPos(:,1)))/2.2,max(sPos(:,2)),mz];
		rightEye0 = [(mx+max(sPos(:,1)))/2.2,max(sPos(:,2)),mz];
		leftEye = find_closest_dipole_from( sPos, leftEye0, physicalModel.constrainedOrientation );
		rightEye = find_closest_dipole_from( sPos, rightEye0, physicalModel.constrainedOrientation );

		sources = [leftEye,rightEye];
	elseif(strcmp(params.position,'occipital'))
		assert(params.howMany==1);
		mx = (max(sPos(:,1))+min(sPos(:,1)))/2;
		mz = (max(sPos(:,3))+min(sPos(:,3)))/2;
		backCenter0 =  [mx,min(sPos(:,2))*0.9,mz];
		backCenter = find_closest_dipole_from( sPos, backCenter0, physicalModel.constrainedOrientation );

		sources = [backCenter];
	elseif(strcmp(params.position,'frontal'))
		assert(params.howMany==1);
		mx = (max(sPos(:,1))+min(sPos(:,1)))/2;
		mz = (max(sPos(:,3))+min(sPos(:,3)))/2;		
		frontCenter0 =  [mx,max(sPos(:,2))*0.9,mz*1.35];
		frontCenter = find_closest_dipole_from( sPos, frontCenter0, physicalModel.constrainedOrientation );

		sources = [frontCenter];		
	elseif(strcmp(params.position,'4points'))
		assert(params.howMany==4);
		mx = (max(sPos(:,1))+min(sPos(:,1)))/2;
		my = (max(sPos(:,2))+min(sPos(:,2)))/2;

		frontalRight0  = [(mx+max(sPos(:,1)))/2,my+max(sPos(:,2))/2,max(sPos(:,3))/2];
		frontalLeft0 = [(mx+min(sPos(:,1)))/2,my+max(sPos(:,2))/2,max(sPos(:,3))/2];
		parietalRight0  = [(mx+max(sPos(:,1)))/2,my-max(sPos(:,2))/2,max(sPos(:,3))/2];
		parietalLeft0 = [(mx+min(sPos(:,1)))/2,my-max(sPos(:,2))/2,max(sPos(:,3))/2];
		leftParietalCenter = find_closest_dipole_from( sPos, parietalLeft0, physicalModel.constrainedOrientation  );
		rightParietalCenter = find_closest_dipole_from( sPos, parietalRight0, physicalModel.constrainedOrientation );
		leftFrontalCenter = find_closest_dipole_from( sPos, frontalLeft0, physicalModel.constrainedOrientation  );
		rightFrontalCenter = find_closest_dipole_from( sPos, frontalRight0, physicalModel.constrainedOrientation  );
		sources = [leftParietalCenter, rightParietalCenter, leftFrontalCenter, rightFrontalCenter];
	elseif(strcmp(params.position,'volume'))
		sources = 1:size(physicalModel.A,2);
	elseif(strcmp(params.position,'surface'))
		sources = 1:size(physicalModel.A,1);
		layer = 2;
	else
		assert(false, sprintf('Unknown sourcetype ''%s''', params.position));
	end


end

