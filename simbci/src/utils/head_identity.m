
function model = head_identity(varargin)
% Generates an 'identity' leadfield. It may be useful for debugging purposes.
% It has no physiological or electromagnetic modelling intent.
%
% The sources are laid out in a 2D grid and the electrodes are based in a
% similar grid above them in z. The transform A is just an identity matrix.
%
% This leadfield has the property that it is perfectly information
% preserving (trivially -- the transform passes the sources as-is).
%

	% Parse inputs
	p = inputParser;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'numSources', 256,  @isint);

	p.parse(varargin{:});

	params = p.Results;

	%%%%%%%%%%%%%%%

	model = [];
	model.filename = '@head_identity';
	model.A = eye(params.numSources);
	model.sourcePos = zeros(params.numSources,3);
	model.electrodePos = zeros(params.numSources,3);
	model.dipolesOrientation = zeros(params.numSources,3);
	model.constrainedOrientation = true;
	model.id = sprintf('identity%d', params.numSources);
	model.params = [];
	model.params.centerAndScale = true;

	gridLen = ceil(sqrt(params.numSources));

	lp1 = linspace(-1,1,gridLen);
	cnt = 1;
	for i=lp1
		for j=lp1
			if(cnt>params.numSources)
				break;
			end
			model.sourcePos(cnt,:) = [i,j,0];
			model.electrodePos(cnt,:) = [i,j,1];
			model.dipolesOrientation(cnt,:) = [0,0,1];
			cnt = cnt + 1;
		end
	end

end

