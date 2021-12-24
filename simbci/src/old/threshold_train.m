
function pipeline = threshold_train(X, labels, numClasses, pipeline)

	% ERD: classify with the label of the ROI exhibiting the highest 'power'
	% average.

	ROIs = pipeline.experimentalROIs;
	if(size(pipeline.physicalModel.sourcePos,1) == 3*size(X,2))
		% previous component probably dropped from 3dof dipoles to 1dof
		% dipoles
		for i=1:length(pipeline.experimentalROIs)
			ROIs{i} = ROIs{i}(3:3:end) ./ 3;
		end
	end
	model = [];
	model.experimentalROIs = ROIs;

	pipeline.modelClassifier = model;
end
