classdef core_head
%CLASS_HEAD Models the head of the subject
%
% Includes the forward transform and information about the dipole
% and electrode positions.

	properties
		name                   % name of the model
		A                      % leadfield matrix
		sourcePos              % 3D dipole locations
		electrodePos           % 3D electrode locations
		dipolesOrientation     % 3D orientation of each dipole
		constrainedOrientation % if true, every dipole has 1 dof, otherwise 3
		landmarks              % Can contain expert defined landmark sets as in {'landmark1name',[dipole1 dipole2 ...],'landmark2Name',...}
		electrodesDiscarded    % If the leadfield loading dropped some electrodes, they are listed here

		usedParams
	end

	methods

	function obj = core_head(varargin)
	% CLASS_HEAD Default constructor to assemble a head model
	%
	% Constructs a forward (head) model, either from a file or artificially
	%
	% If the loaded model file requests to drop some electrodes with a struct member
	% 'electrodesToDiscard', these will be dropped and marked in 'electrodesDiscarded'.
	%

		% Parse inputs
		p = inputParser;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p,'filename',             'sabre:/models/leadfield-sphere.mat', @ischar);
		addParameter(p,'centerAndScale',       true,  @islogical);
		addParameter(p,'calibrateLeadfield',   'off', @ischar);
		addParameter(p,'adhocLandmarks',       0,     @isint);
		addParameter(p,'visualize',            false, @islogical);
		addParameter(p,'headComposer',         @null, @isfun);
		addParameter(p,'headComposerParams',   {},    @iscell);

		p.parse(varargin{:});

		params = p.Results;

		%%%%%%%%%%%%%%

		% Did the user request an artificially generated model?
		if(~isequal(params.headComposer, @null))
			tmpModel = params.headComposer(params.headComposerParams{:});
		else
			tmpModel = load(expand_path(params.filename));
		end

		if(isfield(tmpModel, 'electrodesToDiscard'))
			electrodesToKeep = setdiff(1:size(tmpModel.A, 1), tmpModel.electrodesToDiscard);
			tmpModel.A = tmpModel.A(electrodesToKeep, :);
			tmpModel.electrodePos = tmpModel.electrodePos(electrodesToKeep,:);
		end

		% Add any preprocessing steps here we might need globally

		% replicate source position array to match leadfield dimensions if not done already
		if(size(tmpModel.A,2)==3*size(tmpModel.sourcePos,1))
			idxs=repmat(1:size(tmpModel.sourcePos,1), [3 1]);
			tmpModel.sourcePos = tmpModel.sourcePos(idxs,:);
		end

		% Reposition and rescale the coordinates. This shouldn't affect the forward/inverse,
		% but will make the visualizations more comparable across models. Note that all points
		% in both electrodes and sources should retain their relative distances by this.
		% Note that this will affect the bcicomp4 noise generation that relies on the
		% electrode positions.
		if(params.centerAndScale)
			% center the coordinates by a kind of mass center
			min1 = min(tmpModel.electrodePos);
			max1 = max(tmpModel.electrodePos);
			me = (max1+min1)/2;
			tmpModel.electrodePos = tmpModel.electrodePos - repmat(me, [size(tmpModel.electrodePos,1) 1]);
			tmpModel.sourcePos = tmpModel.sourcePos - repmat(me, [size(tmpModel.sourcePos,1) 1]);

			% scale all coordinates by the x-axis so different models are roughly in the same scale.
			% we keep the aspect ratio by scaling everything with a single
			% scale
			mi = min(tmpModel.electrodePos(:));
			ma = max(tmpModel.electrodePos(:));

			tmpModel.electrodePos(:) = 2*(tmpModel.electrodePos(:)-mi)/(ma-mi)-1; % [-1,1]
			tmpModel.sourcePos(:) = 2*(tmpModel.sourcePos(:)-mi)/(ma-mi)-1;

		end

		if(params.adhocLandmarks > 0)
			% one possibility is to set landmarks while loading the physical model, e.g. eyes, distractors, etc
			
			% cluster, e.g. for distractors
			ss = statset; ss.MaxIter = 500;
			[~,C] = kmeans(tmpModel.sourcePos,tmpModelParams.adhocLandmarks,'Options',ss);
			tmpModel.centroids = zeros(size(C,1),1);
			for i=1:size(C,1)
				[~,minIdx] = min(sum(abs(tmpModel.sourcePos - repmat(C(i,:), [size(tmpModel.sourcePos,1) 1])),2));
				tmpModel.centroids(i) = minIdx;
			end
		end

		if(strcmp(params.calibrateLeadfield,'off'))
			% fine, NOP
		elseif(strcmp(params.calibrateLeadfield,'perElectrode'))
			% This is a suspicious and experimental procedure that aims to
			% bring the measurements from the different electrodes to the same scale by
			% scaling the rows of the leadfield according to how
			% multidimensional, dense Gaussian noise of unit variance gets projected by it.
			% After scaling, the variance of such data will be approx 1 in all electrodes.
			% This procedure might be better than scaling the data, as
			% scaling might interfere with the inverse transform, whereas now
			% any inverse made from the calibrated matrix will include the scaling.
			% tmpS = randn(size(tmpModel.A,2),10000);
			% surfaceX = tmpModel.A * tmpS;
			% scale = std(surfaceX,[],2);
			scale = sqrt(mean(tmpModel.A.^2,2));
			tmpModel.originalCalibration = scale;
			tmpModel.A = tmpModel.A ./ repmat(scale, [1 size(tmpModel.A,2)]);
			% scale2 = sqrt(mean(tmpModel.A.^2,2));
			% surfaceXtest = tmpModel.A * tmpS;
			% testScale = std(surfaceXtest,[],2); % should be approx 1.
		elseif(strcmp(params.calibrateLeadfield,'global'))
			% scale the leadfield so the different leadfields have approx the
			% same magnitude.
			% division by scalar shouldn't change the properties of the
			% leadfield except for the scale the forward projected data.
			tmpModel.A = tmpModel.A ./ std(tmpModel.A(:));
		else
			assert(false, 'Unknown parameter');
		end

		assert(size(obj.electrodePos,1) == size(obj.A,1), 'Number of electrodes and leadfield row count do not match');
		assert(size(obj.sourcePos,1) == size(obj.A,2), 'Number of source positions and leadfield column count do not match');
		assert(size(obj.dipolesOrientation,1) == size(obj.A,2), 'Dipole orientation count and leadfield column count do not match');

		% Import to object scope
		obj.name = params.filename;
		obj.A = tmpModel.A;
		obj.sourcePos = tmpModel.sourcePos;
		obj.electrodePos = tmpModel.electrodePos;
		if(isfield(tmpModel,'dipolesOrientation'))
			obj.dipolesOrientation = tmpModel.dipolesOrientation;
		else
			obj.dipolesOrientation = [];
		end
		obj.constrainedOrientation = tmpModel.constrainedOrientation;
		if(isfield(tmpModel,'electrodesToDiscard'))
			obj.electrodesDiscarded = tmpModel.electrodesToDiscard;
		elseif(isfield(tmpModel,'electrodesDiscarded'))
			obj.electrodesDiscarded = tmpModel.electrodesDiscarded;
		end

		obj.usedParams = params;

		if(params.visualize)
			figure();
			obj.visualize();
			drawnow;
		end
	end

	function paramList = get_params(obj)
	% Returns the used parameters.
	%
	% defaultParams = core_head().get_params();
	%
		paramList = struct_to_list(obj.usedParams);
	end

	function X = forward_transform(obj, S, varargin)
	% Apply forward model on volumetric data and return surface measurements

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'type',                   'basic', @ischar);
		addParameter(p, 'visualize',              false, @islogical);

		p.parse(varargin{:});
		params = p.Results;

		%%%%%%%%%%%%%%

		if(strcmp(params.type,'basic'))
			% @FIXME remove the useless S transpose by generating data differently
			X = (obj.A * S')';
		else
			assert(false, sprintf('Unknown forward type %s\n',params.type) );
		end

		if(params.visualize)
			figure();
			imagesc(X);
			title('Surface data');
			xlabel('Electrode'); ylabel('Sample(t)');
		end

	end

	function [indexes,layer] = get_landmark( obj, landmarkName )
	% Finds a set of source indexes in the volume corresponding to
	% a predefined landmark.
	%
	% The 'landmarkName' parameter identifies the landmark which
	% must exist in the head model and is assumed to have been
	% identified by a neurophysiologist. The landmark can be
	% anything from a single dipole to a set of dipoles defining a region.
	%
	% If your head model lacks such information, use independent function
	% where_heuristic() to find certain landmarks heuristically.
	%
		indexes = get_parameter(obj.landmarks, landmarkName);
		layer = 1; % always in the volume for now
	end
%
	function visualize(obj, highLightSources, highLightElectrodes, ~, sourceHighLightColor, radius)

		assert(~isempty(obj.A), 'Construct first');

		if(nargin<2)
			highLightSources=[];
		end
		if(nargin<3)
			highLightElectrodes=[];
		end
		if(nargin<4)
			% Even if input was unconstrained, sLoreta can output constrained sources, i.e. 1 dof per source. If so, we skip the source mapping to 1 dof below.
			% constrainedOrientationHighlights = false;
		end
		if(nargin<5)
			sourceHighLightColor = 'r*';
		end
		if(nargin<6)
			radius = 40;
		end

		%clf; hold on;
		hold on;
		plot3(obj.sourcePos(:,1),obj.sourcePos(:,2),obj.sourcePos(:,3),'g.');
		if(~isempty(highLightSources))
			plot3(obj.sourcePos(highLightSources,1),obj.sourcePos(highLightSources,2),obj.sourcePos(highLightSources,3),sourceHighLightColor, 'markers', radius);
		end

		plot3(obj.electrodePos(:,1),obj.electrodePos(:,2),obj.electrodePos(:,3),'b.');
		if(~isempty(highLightElectrodes))
			hold on;
			plot3(obj.electrodePos(highLightElectrodes,1),obj.electrodePos(highLightElectrodes,2),obj.electrodePos(highLightElectrodes,3),'r*');
		end
		xlabel('x'); ylabel('y'); zlabel('z');
		view(-130,30);

		grid on;

		title(sprintf('Leadfield %s', obj.name));

		if(obj.usedParams.centerAndScale)
			xlim([-1.5 1.5]);
			ylim([-1.5 1.5]);
			zlim([-1.5 1.5]);
		end

	end

	function save_to_file(obj, filename)
	% Saves the objects properties to a file; not the object itself
	% (assume loader might lack class source)
	%
	% n.b. if loaded leadfield contained 'electrodesToDiscard', the result won't be
	% identical to the originally loaded file.

		A = obj.A;
		sourcePos = obj.sourcePos;
		electrodePos = obj.electrodePos;
		dipolesOrientation = obj.dipolesOrientation;
		constrainedOrientation = obj.constrainedOrientation;
		electrodesDiscarded = obj.electrodesDiscarded;	% note: *not* electrodesToDiscard as this has been already done
		landmarks = obj.landmarks;

		save(filename,'A','sourcePos','electrodePos','dipolesOrientation','constrainedOrientation','landmarks','electrodesDiscarded');
	end

	end

end

