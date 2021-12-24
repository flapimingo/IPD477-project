function display_sources( sources, source_positions, fig_title, true_sources )
%UNTITLED Uses scatter3 to plot the sources w/ their amplitude for 1 time
%sample

if(nargin < 4)
	fig_title = 'Sources';
end
if(nargin < 5)
	true_sources = [];
end

if(size(sources,2)==3*size(source_positions,1))
	% if the sources are nonconstrained, show the norm
	X2 = sources .* sources;
	X2 = reshape(X2, 3,[]);
	X2 = sqrt(sum(X2,1));
else
	% just show as-is
	X2 = sources;
end

% quietSources = (abs(X2)<0.01);

%figure;
scatter3(source_positions(:,1), source_positions(:,2),...
		 source_positions(:,3), 50, X2, 'filled');
title(fig_title);
xlabel('X');
ylabel('Y');
zlabel('Z');
xlim([-1 1]);
ylim([-1 1]);

if(~isempty(true_sources))
	hold on;
	scatter3(source_positions(true_sources,1), source_positions(true_sources,2),...
		 source_positions(true_sources,3), 50, 'r+');
	hold off;
end

end

