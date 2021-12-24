classdef loop_these
% This class just stores whatever is given to it. The intent
% is to be able to detect this class object in the parameter
% lists in order to differentiate between two situations
%
% 1) the parameter indicates a desire to loop over a set of values,
% 2) the parameter is an usual matrix or cell array parameter.
%
	properties
		% stores the values of this container
		looped_values
		% optional identifier related to the values,
		% used to find the subset of looped parameters from a parameter tree
		id
	end

	methods
		function obj = loop_these(looped_values,id)
		% looped_values : the values to loop over
		% id : an mnemonic unique name that identifies the value set in question
		%
		% The identifier is used when aggregating results in order
		% to remind the user which parameter was in question, since the
		% parameter key might not have unique meaning globally: i.e. imagine a list
		%      {{'name','method1','params',{'stars',10}},
		%       {'name','method2','params',{'stars','ParisHilton'}}};
		% -> there is no reason to expect method parameters with the same name
		% to mean the same thing (internal to the method), hence
		% 	    {{'name','method1','params',{'stars',loop_these([5,10]},'starsInTheSky'}};
		% 	     {'name','method2','params',{'stars',loop_these({'ParisHilton','BurtReynolds'},'movieStars'}}};
		% More concrete example: signal components all may have parameter called SNR.
		% Just 'SNR' hence does not identify if it was about volume noise, surface noise,
		% signal. This can be specified by giving each loop request a different id.

			obj.looped_values = looped_values;
			if(nargin==2)
				obj.id=id;
			else
				obj.id='';
			end
		end
	end

end

