
function visualize_dataset(set1, varargin)
% visualize a dataset
% This is just a wrapper for proc_view.m signal processing plugin
%
% See also CLASS_VIEW

	proc_view().train(set1, varargin{:}).process(set1);

end

