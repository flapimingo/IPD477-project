
function pipeline = glmnet_train(X, labels, numClasses, pipeline)

	model = cvglmnet(X, labels, 'binomial', pipeline.pipeParams.classifierParams.opts, 'class');

	pipeline.modelClassifier = model;

