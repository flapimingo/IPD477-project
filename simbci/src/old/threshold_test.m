
function [prediction,raw] = threshold_test(X, model)
% threshold_train.m may be having a different convention than the rest by
% classifying with the highest power. Care should be taken to follow the
% convention that 'lowered alpha/beta power contralaterally' means 'activity
% ipsilaterally' if we're talking about alpha/beta depression. (i.e. alpha
% relaxation rhythm of the motor cortex on the left side is temporarily weakened
% by motor activity/imagination of the right hand).

ROIs = model.experimentalROIs;

raw = zeros(size(X, 1), length(ROIs));

for i=1:length(ROIs)
	% Finding the max 'power' dipole to make the decision
	% raw(:, i) = max(abs(X(:, ROIs{i})), [], 2);
	% Integrate 'powers' over the ROIs
	raw(:, i) = sum(abs(X(:, ROIs{i})), 2) / length(ROIs{i});
end

[foo, prediction] = max(raw, [], 2);

% visualize_physicalmodel(pipeline.physicalModel, leftIndexes); title('Left');
% visualize_physicalmodel(pipeline.physicalModel, rightIndexes); title('Right');
% pause
end

