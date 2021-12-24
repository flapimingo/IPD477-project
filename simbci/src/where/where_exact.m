function [ sources, layer ] = where_exact( physicalModel, varargin )
% Given a head model, returns dipoles corresponding to positions defined in the model
%
% position : a string or a cell of strings (to obtain indexes for several locations)
% 
% layer == 1 volume, 2 surface
%

	% Parse inputs
	p = inputParser;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	iscellorchar = @(x) (ischar(x) || iscell(x));

	addParameter(p,'position',             'eyes',  iscellorchar);

	params = p.Results;

	%%%%%%%%%%%%%%

	if(iscell(params.position))
		sources = cell(length(params.position),1);
		layers = cell(length(params.position),1);
		for i=1:length(sources)
			[sources{i},layer] = physicalModel.get_landmark(params.position{i}); % @fixme assumes all same layer
		end
	else
		[sources,layer] = physicalModel.get_landmark(params.position);
	end

end

