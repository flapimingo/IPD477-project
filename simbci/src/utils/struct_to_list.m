function listOut = struct_to_list( structIn )
%STRUCT_TO_LIST Returns a struct as a key,value cell list

	if(isempty(structIn))
		listOut = {};
	else
		tmp = cat(2,fieldnames(structIn),struct2cell(structIn));
		listOut = reshape(tmp', [1 numel(tmp)]);
	end
	
end

