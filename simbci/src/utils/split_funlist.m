function [ fun,funParams ] = split_funlist( list )
%SPLIT_FUNLIST Splits a {@cell, 'blah',3,'duh',5} type lists to fun,funParams pair

	if(iscell(list)) 
		fun = list{1};
		funParams = list(2:end);
	else
		fun = list; 
		funParams = {};
	end

end

