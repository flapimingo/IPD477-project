function [ prediction,raw ] = md_classifier_test( X, model)
%MD_CLASSIFIER_TEST uses MD to classify samples

raw = zeros(size(X, 1), model.numberClasses);

featsPerClass = size(X, 2) / model.numberClasses;

for j=1:model.numberClasses
	taskFeats = X(:, ((j-1) * featsPerClass + 1):(j * featsPerClass));
	for i=1:size(X, 1)

		raw(i, j) = compute_point_mahalanobis_distance(taskFeats(i, :), model.averages{j},...
													   model.invCovariances{j});
	end
end

[~, prediction] = min(raw, [], 2);

end

