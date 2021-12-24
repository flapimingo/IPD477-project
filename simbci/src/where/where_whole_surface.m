function [ sources, layer ] = where_whole_surface( physicalModel, varargin )
% Just returns all the electrodes
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

	sources = 1:size(physicalModel.A,1);
	layer = 2;

end

