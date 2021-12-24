function val = isfunlist( x )
% Is the input either a function handle or a list with the first arg a function handle

val = isa(x,'function_handle');
if(~val && ~isempty(x))
	val = isa(x{1},'function_handle');
end

end

