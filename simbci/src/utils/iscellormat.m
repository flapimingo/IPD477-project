function val = iscellormat( x )
% Is the input either a cell or a matrix?

	val = (isnumeric(x) || iscell(x));

end

