function experimentalROIs = roi_heuristic( physicalModel, varargin )
% Guesses ROIs around specified centers
%
% where                 - function to locate the center of the ROI
% whereParams           - Parameters to the locating function
% ROIScale              - Controls ROI size
% ROIDelta              - 3D direction & power to deviate the ROI to
% allowOverlap          - Can the ROIs overlap?
%
% Each ROI is a sphere of diameter average brain scale * scale ratio
%
% @TODO When same model is used to generate and test, if the same
% position name ('position') is used for both, this mechanism
% will likely return a ROI which is perfectly centered on the
% generating dipoles. Some mechanism should be implemented to
% allow testing effect of misplacing the ROI. Note that core_head.m
% itself should be deterministic and the ROI misplacement should
% be similar across construct() calls so it matches in train & test.
%
% @TODO this function could be refactored into a generic 'where'
% function that'd be able to return both single dipoles and regions
%
	% Parse inputs
	p = inputParser;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'where',                  @where_heuristic,   @isfunlist);      % where the activity is expected
	addParameter(p','ROIDelta',               [],               @iscellormat);     % ROI details
	addParameter(p','ROIScale',               0.2,              @isnumeric);     % ROI details
	addParameter(p','allowOverlap',           true,             @islogical);     % Can the ROIs overlap?

	p.parse(varargin{:});

	params = p.Results;
	%%%

	[whereFun,whereParams] = split_funlist(params.where);
	
	sources = whereFun(physicalModel,whereParams{:});

	if(~isempty(params.ROIDelta))
		% deviate the source (and subsequently the ROI) to some direction specific to the ROI
		if(~iscell(params.ROIDelta))
			% if delta is just a matrix, give each ROI the same delta
			params.ROIDelta = repmat({params.ROIDelta},[1 length(sources)]);
		end
		if(~physicalModel.constrainedOrientation && 3*length(params.ROIDelta)==length(sources))
			params.ROIDelta = repmat(params.ROIDelta,[3 1]);
			params.ROIDelta = params.ROIDelta(:);
		end
			
		assert(length(params.ROIDelta)==length(sources),'Need a delta per ROI');

		for i=1:length(sources)
			if(any(params.ROIDelta{i}~=0))
				tmp = find_neighbours(sources(i), 2, 1, physicalModel, params.ROIDelta{i});
				sources(i) = tmp(2); % first neighbour is always the source itself
			end
		end
	end

	% assume the scale is isometric to all directions, use ear-ear direction to
	% get an estimate of the scale. Spec ROI to be a ball with a partial radius
	% of this scale.
	distance = sqrt(min(physicalModel.sourcePos(:,1)).^2 + max(physicalModel.sourcePos(:,1)).^2);
	distance = params.ROIScale * distance;

	DIMs = size(physicalModel.sourcePos,1);

	experimentalROIs{length(sources)} = {};
	for i=1:length(sources)
		% Get the center of the exact ROI
		center = physicalModel.sourcePos(sources(i), :);
		% Find the sources closest to this center
		expROIIndexes = find( sum( (physicalModel.sourcePos - repmat(center,  [DIMs 1])).^2, 2) <= distance^2);
		experimentalROIs{i} = expROIIndexes;
	end

	% Check if any ROIs are overlapping
	if(~params.allowOverlap)
		for i=1:length(experimentalROIs)
			for j=(i+1):length(experimentalROIs)
				commonDipoles = intersect(experimentalROIs{i}, experimentalROIs{j});
				if (~isempty(commonDipoles))
					fprintf('WARNING : experimental ROIs %d and %d are overlapping. Was this intended?\n', i,j);
					break; % Only signaling the first overlap.
				end
			end
		end
	end

	% Note that we don't have to duplicate the ROI in case of the
	% nonconstrained orientation. In that case, sourcePos includes 3 position
	% vectors for each dipole, and their indexes have already been picked
	% up by the above code.

end

