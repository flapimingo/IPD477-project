function [X, se_sslofo] = sslofo_inverse(G,Vmes, constrained, varargin)

	% FIXME, assumes source positions as input arg
	srcPos = [];
	
    options.foo = false;
    [X, se_sslofo] = sslofo_inverse_impl(G,Vmes, options, srcPos);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% simulate two sources in the realistic head model
% Authors: Hesheng Liu & Paul Schimpf             
% Email: hesheng@wsu.edu , schimpf@wsu.edu 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [X, se_sslofo] = sslofo_inverse_impl(G,Vmes, options, srcPos)

    if ~isfield(options, 'thres')
        Lx = norm(max(srcPos(1,:))-min(srcPos(1,:)));
        Ly = norm(max(srcPos(2,:))-min(srcPos(2,:)));
        Lz = norm(max(srcPos(3,:))-min(srcPos(3,:)));
        thres = min([Lx Ly Lz])/3;
    else
        thres = options.thres;
    end

    if ~isfield(options, 'looptime')
        looptime = 40;
    else
        looptime = options.looptime;
    end

    scope = findneighbor(srcPos, thres);
    pct = 1; %default
    S = svd(G);
    lambda = sqrt(S(1))*pct/100;
    [se_sslofo, X]=subsslofot(Vmes,G,scope,lambda,looptime);

end

