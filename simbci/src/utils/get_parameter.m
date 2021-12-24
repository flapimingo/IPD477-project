function value = get_parameter( paramList, varargin )
% Usage: value = get_parameter(list,key1,...,keyN)
%
% Retrieve a parameter value from a cell array of {'key',value'} pairs.
% Can also be used to return a value from a sublist by specifying multiple keys;
% each key except the last should identify a nested sublist.

	assert(iscell(paramList), 'Input 1 is not a cell array');
	assert(mod(length(paramList),2)==0, 'List does not consist of param,value pairs');
	assert(length(varargin)>=1, 'Need at least a (list,key) as input');

	key = varargin{1};
	rest = {varargin{2:end}};

	% Only match keys, not values
	index = find(strcmp(paramList(1:2:end), key))*2-1;

	assert(~isempty(index), 'Key not found in list');
	assert(length(index)==1, 'Key is not unique in list');

	if(length(varargin)==1)
		% only one key left, return value
		value = paramList{index+1};
	else
		% Look deeper with the next key
		value = get_parameter(paramList{index+1}, rest{:});
	end

end

