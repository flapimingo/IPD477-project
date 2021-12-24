function result = expand_parameters( varargin )
% Given a parameter list as input, i.e. expand_parameters(paramList{:}),
% returns a set of parameter lists where each loop_these() class has
% been replaced with its contained values.
%
% expand_parameters_only() can be used to retrieve the unrolled
% parameters and their identities.
%
% @FIXME test that this and the related functions work properly if there's
% nothing to expand.
%

%	assert(iscell(outList));
	if(isempty(varargin))
		result = { {} };
		return;
	end

	if(length(varargin)>1)
		% not a leaf, split
%		fprintf(1,'Split [1,%d]\n',length(varargin)-1);

		tmp1 = expand_parameters(varargin{1});
		tmp2 = expand_parameters(varargin{2:end});

		% make all pairs of the returned results
		len1 = size(tmp1,1);
		len2 = size(tmp2,1);

		assert(len1>0 && len2>0);

%		fprintf(1, 'Merge [%d,%d]+[%d,%d]\n',size(tmp1,1),size(tmp1,2),size(tmp2,1),size(tmp2,2));

		% Could perhaps be more elegant/faster but this works for our small-scale usage
		cnt = 1;
		result = cell(len1*len2,1);
		for i=1:len1
			for j=1:len2
				val1 = tmp1{i}; val2 = tmp2{j};
				if(~iscell(val1)) val1 = {val1}; end;
				if(~iscell(val2)) val2 = {val2}; end;
				result{cnt} = {val1{:},val2{:}};
				cnt = cnt + 1;
			end
		end
		assert(size(result,1)>0);
		% result
	else
		% leaf
		arg = varargin{1};

		if(iscell(arg))
%			fprintf(1,'Cell\n');
			tmp = expand_parameters(arg{:});
			result = cell(size(tmp,1),1);
			for i=1:size(tmp,1)
				val1 = tmp{i};
				if(~iscell(val1)) val1 = {val1}; end;
				result{i} = { { val1{:} } };
			end
		elseif(isa(arg,'loop_these'))
%			fprintf(1,'Expand leaf -> %d values\n', length(varargin{1}.looped_values));
			obj = varargin{1};
			values = obj.looped_values;
			result = cell(length(values),1);
			if(iscell(values))
				for i=1:length(values);
					result{i} = values{i};
				end
			else
				for i=1:length(values);
					result{i} = values(i);
				end
			end
			assert(size(result,1)>0);
			%result
			%size(result)
		else
			% fprintf(1,'Atom %c\n', arg);
%			fprintf(1,'Atom\n');
			result = { arg };
		end
	end
end
