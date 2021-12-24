
classdef proc_csp
% Common Spatial Patterns (CSP) feature extraction without any other processing

	properties
		modelCSP
		usedParams
	end
	methods

	function [obj, feats] = train(obj, trainData, varargin )
	% Train a CSP model

		% parse arguments
		p = inputParser;
		p.KeepUnmatched = false;
		p.CaseSensitive = true;
		p.PartialMatching = false;

		addParameter(p, 'tikhonov',               0,               @isnumeric); % regularization
		addParameter(p, 'shrink',                 0,               @isnumeric); % regularization
		addParameter(p, 'dim',                    2,               @isint);

		p.parse(varargin{:});
		params = p.Results;

		%%%%%%%%%%%%

		obj.modelCSP = obj.csp_train_impl(trainData, params );
		obj.usedParams = params;

		% do not extract any features, let caller do on demand
		feats = [];

	end


	function feats = process(obj, dataset)
	% Extract CSP features
		assert(~isempty(obj.modelCSP));

		feats = obj.csp_extract_impl(dataset, obj.modelCSP);
	end

	end

	methods(Static,Access=protected)
		
	function [csps,d] = csp_train_impl(trainData, params )
	% Train a multiclass CSP model. Makes several 1vs all CSPs, then
	% chooses a few filters from each.
	%
	% @note might be meaningful to choose just the in-class filters, not sure.
	
		n = params.dim;
		numClasses = trainData.numClasses;

		assert(rem(n,2) == 0, 'CSP requires a dimension multiple of 2');
		assert(numClasses >= 2, 'Data doesnt have at least 2 classes');

		if(numClasses==2)
			% This hack prevents doing 1vs2 and 2vs1 in the two-class case
			numClasses = 1;
		end

		[nSamples,nElectrodes] = size(trainData.X);

		csps=zeros(nElectrodes,n*numClasses);
		d = zeros(nElectrodes,numClasses);

		for i=1:numClasses

			% Trial identifiers corresponding to trials which belong to this class and which do not
			% note that class label 0 (rest) is ignored on purpose.
			trialsIn = find(trainData.trialLabels==i);
			trialsOut = find(trainData.trialLabels~=i);

			% Compute covariance for data in-class
			coIn = zeros(nElectrodes);
			for j=1:length(trialsIn)
				tmp = trainData.X(trainData.trialIds==trialsIn(j), :);

				co = cov(tmp);
				co = co./sum(diag(co)); %% regularization, each trial will have similar contrib

				coIn = coIn + co;
			end
			coIn = coIn / length(trialsIn);

			% Compute covariance for data out-of-class
			coOut = zeros(nElectrodes);
			for j=1:length(trialsOut)
				tmp = trainData.X(trainData.trialIds==trialsOut(j), :);

				co = cov(tmp);
				co = co./sum(diag(co)); %% regularization, each trial will have similar contrib

				coOut = coOut + co;
			end
			coOut = coOut / length(trialsOut);

			% Regularization block, resembles Lotte & Guan ...
			diagCov = eye(size(coIn,2));
			coIn  = ( params.shrink*diagCov+(1-params.shrink)*coIn + params.tikhonov*diagCov);
			coOut = ( params.shrink*diagCov+(1-params.shrink)*coOut + params.tikhonov*diagCov);

			[filters,sD] = eig(inv(coOut)*coIn);

			% sort the eigenvectors
			[sD,idx1] = sort(diag(sD),1,'descend');
			filters = filters(:,idx1);

			csps(:,(i-1)*n+1:i*n) = [filters(:,1:n/2),filters(:,(end-n/2+1):end)];
			d(:,i) = sD(:)';
		end

		if(any(isnan(csps)))
			fprintf(1, 'CSP Warning: Ouch, nans in CSP filters...\n');
			csps(isnan(csps)) = 0;
		end
		if(any(~isreal(csps)))
			fprintf(1, 'CSP Warning: Ouch, imaginary numbers in CSP filters...\n');
			csps = real(csps);
		end

	end % function
	
	function feats = csp_extract_impl(dataset, modelCSP)
	% Evaluates the csp model
	
		feats = (modelCSP' * dataset.X')';

	end % function

	end % methods(static,access=protected)
	
end % classdef


