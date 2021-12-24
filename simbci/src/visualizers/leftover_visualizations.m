
% @TODO these should be rethought and inserted where appropriate

if(simulationParams.enable_plots)
	visualize_physicalmodel(physicalModel,trainData.ROI);title('Sources of interest'); % highlight MI dipoles
	[dummy, tmp] = generate_noise(1, simulationParams.volumeNoiseParams, physicalModel);
	if(isfield(tmp,'ROI'))
		visualize_physicalmodel(physicalModel, tmp.ROI);title('Artifact sources');	 % highlight eye dipoles
	end
	visualize_dataset(trainData.S, simulationParams.generateParams.samplingFreq,...
		15, 'Left source', trainData.ROI(1)); 	% Plot 1st comp of 1st MI src dipole
	visualize_dataset(trainData.S, simulationParams.generateParams.samplingFreq,...
		15, 'Right source', trainData.ROI(2)); 	% Plot 1st comp of 2nd MI src dipole
	visualize_dataset(trainData.X, simulationParams.generateParams.samplingFreq,...
		15, 'Surface');



end

