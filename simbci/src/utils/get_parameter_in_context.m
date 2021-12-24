function value = get_parameter_in_context( paramList, contextKey, contextValue, varargin )
% Usage: value = get_parameter(list,contextKey, contextValue, key1,...,keyN)
%
% Retrieve a parameter value from a nested cell array. The function will first look
% for all subtrees where a cell has a {'key',value'} pairs matching 'contextKey' and
% 'contextValue'. Then, get_parameter() is called on this subtree.
%
% @FIXME this function currently does not differentiate between not finding the
% context and the return value being empty in the context - empty is returned in both cases.

	value = {};
	if(isempty(paramList))
		return;
	end

	assert(iscell(paramList), 'Input 1 is not a cell array');
	assert(mod(length(paramList),2)==0, 'List does not consist of param,value pairs');
	assert(length(varargin)>=1, 'Need at least a (list,key) as input');

	% Only match keys, not values
	index = find(strcmp(paramList(1:2:end), contextKey))*2-1;
	if(~isempty(index) && isequal(paramList{index+1}, contextValue))
		% Context found, get value
		value = get_parameter(paramList, varargin{:});
	else
		% Context not found, descend into sublists
		for i=1:length(paramList)
			if(iscell(paramList{i}))
				value = get_parameter_in_context(paramList{i}, contextKey, contextValue, varargin{:} );
				if(~isempty(value))
					return;
				end
			end
		end
	end

end

