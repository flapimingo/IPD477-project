
function model = head_blur(varargin)
% Generates a 'blurring' leadfield. It may be useful for debugging purposes.
% It has no physiological or electromagnetic modelling intent.
%
% The sources are laid out in a 2D grid and the electrodes are based in a
% similar grid above them in z. The transform A is a Gaussian blur:
% each electrode integrates the sources under it with a Gaussian weight.
% The weight is strongest on the source right under the electrode.
%
% This leadfield has the property that its information loss can be
% controlled a little: increasing parameter 'spread' will (slowly) lead
% to the decrease of the rank of A as the width of the blur grows.
%

	% Parse inputs
	p = inputParser;
	p.CaseSensitive = true;
	p.PartialMatching = false;

	addParameter(p, 'numSources', 256,  @isint);
	addParameter(p, 'spread',       2,  @isnumeric);

	p.parse(varargin{:});

	params = p.Results;

	%%%%%%%%%%%%%%%

	sideLen = floor(sqrt(params.numSources));
	assert(sideLen*sideLen == params.numSources, 'NumSources must be k*k for some integer k');

	model = [];
	model.filename = '@head_blur';
	model.A = eye(params.numSources);
	model.sourcePos = zeros(params.numSources,3);
	model.electrodePos = zeros(params.numSources,3);
	model.dipolesOrientation = zeros(params.numSources,3);
	model.constrainedOrientation = true;
	model.id = sprintf('blur%d, s=%1.2f', params.numSources,params.spread);
	model.params = [];
	model.params.centerAndScale = true;

	f = fspecial('gaussian',[11 11], params.spread);

	lp = linspace(-1,1,sideLen);

	cnt = 1;
	for i=1:sideLen
		for j=1:sideLen
			img = zeros(sideLen,sideLen);
			img(i,j) = 1;
			img = imfilter(img, f, 'same');
			model.A(cnt,:) = img(:);
			model.sourcePos(cnt,:) = [lp(i),lp(j),0];
			model.electrodePos(cnt,:) = [lp(i),lp(j),1];
			model.dipolesOrientation(cnt,:) = [0,0,1];
			cnt = cnt + 1;
		end
	end

end

