function [ sources, layer ] = where_whole_volume( physicalModel, varargin )
% Just returns all the sources
% 
% layer: 1==volume, 2==surface
%

	% Parse inputs
	p = inputParser;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	% takes no arguments

	p.parse(varargin{:});

	%%%%%%%%%%%%%%

	sources = 1:size(physicalModel.A,2);
	layer = 1;

end

