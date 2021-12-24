 
function [model,feats] = sloreta_inverse_train(trainData, params)

	% No training needed, just store the forward model
	model=[];
	model.modelA = physicalModel.A;
    model.modelSourcePos = physicalModel.sourcePos;
	model.params = params;
    
	feats = [];
	
	