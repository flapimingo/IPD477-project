
function [predictions,raw] = glmnet_test(X, model)

	raw = cvglmnetPredict(model, XFeatures, [], 'link');
	predictions = 2*(raw>0)-1;

