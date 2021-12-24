function save_figures( prefix )
%SAVE_FIGURES Dumps all currently open figures to pics/
%   Detailed explanation goes here

	if(nargin<1)
		prefix = 'debug';
	end

	fprintf(1, 'Saving figs to pics/ ...');

	% Delete old pics with the same prefix
	pattern = expand_path(sprintf('sabre:pics/%s*.png', prefix));
	delete(pattern);

	figHandles = get(0,'Children');
	for i=1:length(figHandles)
			h = get(figHandles(i));
			fn = expand_path(sprintf('sabre:pics/%s%03d.png', prefix, h.Number));
			print(h.Number,'-dpng','-r300',fn);
			fprintf(1,'.');
	end
	fprintf(1,' done\n');


end

