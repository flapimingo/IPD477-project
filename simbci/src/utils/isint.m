function val = isint( x )
% Is the input a single integer?

 val = (floor(x)==x);
 val = (length(val)==1);

end

