function pipeline = md_classifier_train( X, labels, numClasses, pipeline )
%MD_CLASSIFIER_TRAIN Summary of this function goes here
%   Detailed explanation goes here

model=[];

model.numberClasses = numClasses;

model.averages = cell(model.numberClasses);
model.invCovariances = cell(model.numberClasses);

trialsPerTask = size(X, 1) / model.numberClasses;
featsPerTask = pipeline.modelExtractor.params.featuresPerLabel;

for i=1:model.numberClasses
	feats = X(:, ((i-1) * featsPerTask + 1):(i * featsPerTask));
	taskFeats = feats(((i-1) * trialsPerTask + 1):(i * trialsPerTask), :);
	co = cov(taskFeats);
	% Adhoc regularization: If co is invertible, result is equal to inv.
	% If not, we get an approximation...
	invCo = pinv(co);
	model.averages{i} = mean(taskFeats);
	model.invCovariances{i} = invCo; % FIXME To check!
end

% FIXME: we can check against training that everything is working!

pipeline.modelClassifier = model;
end

