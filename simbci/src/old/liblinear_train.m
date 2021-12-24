
function pipeline = liblinear_train(X, labels, numClasses, pipeline)

	opts = sprintf('-q -s %d -c %f', pipeline.pipeParams.classifierParams.subType, pipeline.pipeParams.classifierParams.cost);

	pipeline.modelClassifier = liblin_train(labels, sparse(X), opts);


