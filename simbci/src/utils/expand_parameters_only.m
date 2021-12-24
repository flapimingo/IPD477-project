
function result = expand_parameters_only( varargin )
% expand_parameters_only() can be used to retrieve the information
% from a parameter list concerning which parameters have been
% specified as loop_these(), and what are their values. Note
% that this function should be compatible with expand_parameters()
% in its way to recurse so that the results of this call can
% be used to organize/plot the results from iterating over the
% parameters.
%

%	assert(iscell(outList));
	if(isempty(varargin))
		result = { {} };
		return;
	end

	if(length(varargin)>1)
		% not a leaf, split
%		fprintf(1,'Split [1,%d]\n',length(varargin)-1);

		tmp1 = expand_parameters_only(varargin{1});
		tmp2 = expand_parameters_only(varargin{2:end});

		% make all pairs of the returned results
		len1 = size(tmp1,1);
		len2 = size(tmp2,1);


%		assert(len1>0 && len2>0);

%		fprintf(1, 'Merge [%d,%d]+[%d,%d]\n',size(tmp1,1),size(tmp1,2),size(tmp2,1),size(tmp2,2));

		if(len1==0)
			result = tmp2;
		elseif(len2==0)
			result = tmp1;
		else
			% Could perhaps be more elegant/faster but this works for our small-scale usage
			cnt = 1;
			result = cell(len1*len2,1);
			for i=1:len1
				for j=1:len2
					val1 = tmp1{i}; val2 = tmp2{j};
					result{cnt} = {val1{:},val2{:}};
					cnt = cnt + 1;
				end
			end
		end
	%		assert(size(result,1)>0);
	else
		% leaf
		arg = varargin{1};

		if(iscell(arg))
%			fprintf(1,'Cell\n');
			tmp = expand_parameters_only(arg{:});
			result = cell(size(tmp,1),1);
			for i=1:size(tmp,1)
				val1 = tmp{i};
				result{i} = val1;
			end
		elseif(isa(arg,'loop_these'))
%			fprintf(1,'Expand leaf -> %d values\n', length(varargin{1}.looped_values));
			obj = varargin{1};
			values = obj.looped_values;
			result = cell(length(values),1);
			for i=1:length(values);
				if(iscell(values(i)))
					result{i} = {obj.id,values{i}};
				else
					result{i} = {obj.id,values(i)};
				end
			end
%			assert(size(result,1)>0);
		else
			% fprintf(1,'Atom %c\n', arg);
%			fprintf(1,'Atom\n');
			result = { };
		end
	end
end
