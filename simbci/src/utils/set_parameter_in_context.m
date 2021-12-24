function paramList = set_parameter_in_context( paramList, contextKey, contextValue, varargin )
% Usage: list = set_parameter(list,contextKey, contextValue, key1,...,keyN,value)
%
% Inserts or replaces a parameter value in a cell array by first recursively
% finding a sublist where a {'key',value'} pair matches to contextKey and contextValue.
% Then calls set_parameter().
%
% Returns empty list if context was not found
%

	if(isempty(paramList))
		return;
	end

	assert(iscell(paramList), 'Input 1 is not a cell array');
%	assert(mod(length(paramList),2)==0, 'List or sublist does not consist of param,value pairs');
%	assert(length(varargin) >= 2, 'Need at least (list,key,value) as input');

	if(mod(length(paramList),2)==0)
		% might be a key,value list, look for key. Only match keys, not values
		index = find(strcmp(paramList(1:2:end), contextKey))*2-1;
	else
		% might be a list of cell arrays, we'll look deeper
		index = [];
	end

	assert(length(index)<=1, 'Key is not unique in list');

	if(~isempty(index) && isequal(paramList{index+1}, contextValue))
		% context found
		paramList = set_parameter(paramList, varargin{:});
	else
		% context not found, descend to possible sublists
		for i=1:length(paramList)
			if(iscell(paramList{i}))
				tmp = set_parameter_in_context(paramList{i}, contextKey, contextValue, varargin{:});
				if(~isempty(tmp))
					paramList{i} = tmp;
					return;
				end
			end
		end
		% If we didn't return already, nothing was found
		paramList = {};
	end
end

