function print_parameters( paramList, firstCall )
% Usage: print_parameters(list)
%
% Prints a parameter list

	if(~iscell(paramList))
		if(ischar(paramList))
			fprintf(1,' ''%s''',paramList);
		elseif(isnumeric(paramList) || islogical(paramList))
			fprintf(1,' %d',paramList);
		elseif(isfun(paramList))
			fprintf(1,' @%s',func2str(paramList));
		else
			props = whos('paramList');
			fprintf(1,' ?%s', props.class);
		end
	else
		% Look deeper
		fprintf(1,' {');
		for i=1:length(paramList)
			print_parameters(paramList{i}, false);
			if(nargin<2)
				fprintf(1,'\n');
			end
		end
		fprintf(1,'}');
	end

	if(nargin<2)
		fprintf(1,'\n');
	end

end

