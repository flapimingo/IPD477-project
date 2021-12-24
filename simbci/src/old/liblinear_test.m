

function [predictions,raw] = liblinear_test(X, model)

	[predictions, dummy, raw] = liblin_predict(zeros(size(X,1),1), sparse(X), model, '-q');

