function [ sources ] = roi_exact( physicalModel, varargin )
% Given a head model, returns dipoles corresponding to region defined in the model
%
% position : a string or a cell of strings (to obtain indexes for several locations)
%

	sources = where_exact(physicalModel, varargin{:});

end

