
% Transforms data columns to have zero mean and unit variance
function [data,me,sd] = normalize(data,me,sd,alongDim)
	if(nargin<4)
		alongDim = 1;
	end
	if(nargin<3 || isempty(sd))
		sd = std(data, [], alongDim);
	end
	if(nargin<2 || isempty(me))
		me = mean(data,alongDim);
	end

	if(alongDim == 1)
		data = data - repmat( me, [size(data,1) 1]);
		data = data ./ repmat( sd, [size(data,1) 1]);
	else
		data = data - repmat( me, [1 size(data,2)]);
		data = data ./ repmat( sd, [1 size(data,2)]);
	end

end

