

function display_source_movie(S, physicalModel, generationROI, cutDC, useScale, useAbs)

	if(nargin<3)
		generationROI = [];
	end
	if(nargin<4)
		cutDC = true;
	end
	if(nargin<5)
		useScale = true;
	end
	if(nargin<6)
		useAbs = false;
	end

	if(cutDC)
		% This removes the DC across sources per sample and makes the plots more stable
		% from frame to another
		S = S - repmat(mean(S,1),[size(S,1) 1]);
	end

	if(useScale)
		% bring the dataset to [-1 1] scale
		S = S - min(S(:));
		S = (S / max(S(:))*2)-1;
	end

	if(useAbs)
		S = abs(S);
	end

	view(3);
	for i=1:size(S,1)
		[az,el] = view;
		display_sources(S(i,:), physicalModel.sourcePos, '', generationROI);
		view([az,el]);title(i); axis equal;drawnow;
	end

end