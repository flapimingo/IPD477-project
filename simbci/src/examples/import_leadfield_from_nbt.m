%
% Example how to import the leadfield from the 'simulating and estimating EEG sources'
% tutorial of the Neurophysiological Biomarker Toolbox (NBT). The toolbox is kindly
% provided by the Neuronal Oscillations and Cognition Group at the CNCR,
% VU University Amsterdam.
%
% At the time of writing (Jul 2017) the tutorial and the files were available at
% 
% https://www.nbtwiki.net/doku.php?id=tutorial:tutorial_dipoles#.WW3UK1HfOM8
%
% First extract the tutorial archive to the path below; have 'setup_paths.m' run from Sabre first.
%

% This constructs the head model using NBT
addpath(genpath('M:/mypath/tutorial_dipoles'));
nbtHead = head.mri('SubjectPath', 'db/0003');
nbtHead = sensors_to_outer_skin(nbtHead);
nbtHead = make_source_grid(nbtHead, 0.5);
nbtHead = make_bem(nbtHead);
nbtHead = make_leadfield(nbtHead);

% Here we convert the head model to the Sabre conventions
[nElectrodes, nDim, nSources] = size(nbtHead.LeadField);
A = zeros(nElectrodes,nSources*nDim);
for i=1:nDim
	A(:, i:nDim:end) = squeeze(nbtHead.LeadField(:,i,:));
end

sabreHead = [];
sabreHead.A = A;
sabreHead.id = 'nbt0003';
sabreHead.constrainedOrientation = 0;
sabreHead.sourcePos = nbtHead.SourceSpace.pnt;
sabreHead.electrodePos = nbtHead.Sensors.Cartesian;
sabreHead.dipolesOrientation = [];

filepath = expand_path('sabre://contrib/models/nbt0003.mat');  
save(filepath,'-struct','sabreHead');

sabreHead = core_head('filename',filepath);

