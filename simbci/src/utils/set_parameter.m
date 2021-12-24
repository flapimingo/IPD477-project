function paramList = set_parameter( paramList, varargin )
% Usage: list = set_parameter(list,key1,...,keyN,value)
%
% Inserts or replaces a parameter value in a cell array of {'key',value'}
% pairs. The function can also be called with multiple keys to look
% do the same operation in a sublist.
%

	assert(iscell(paramList), 'Input 1 is not a cell array');
	assert(mod(length(paramList),2)==0, 'List or sublist does not consist of param,value pairs');
	assert(length(varargin) >= 2, 'Need at least (list,key,value) as input');

	% The first arg is always a key
	key = varargin{1};
	% The rest can either be more keys, but the last is always 'value'
	rest = {varargin{2:end}};

	% Only match keys, not values
	index = find(strcmp(paramList(1:2:end), key))*2-1;

	assert(length(index)<=1, 'Key is not unique in list');

	if(length(index)==1)
		% key is found

		if(length(rest)>1)
			% multiple keys, look deeper with the next key
			subList = paramList{index+1};
			subList = set_parameter(subList, rest{:});
			paramList{index+1} = subList;
		else
			% one key left, replace value
			value = rest{end};
			paramList{index+1} = value;
		end
	else
		% key not found, insert
		if(length(rest)>1)
			% Multiple keys, insert subkey
			paramList = {paramList{:}, key, set_parameter({},rest{:})};
		else
			% Single key, insert value
			value = rest{end};
			paramList = {paramList{:},key, value};
		end
	end

end

