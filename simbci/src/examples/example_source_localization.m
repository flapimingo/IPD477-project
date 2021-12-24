%
% Example of how the more low level functions can be used to examine
% elementary source localization behavior. For more advanced and
% realistic examples, consider adding noise etc using generate_noise.m
%
clear;

% The head model
model = core_head('filename', 'sabre:/models/leadfield-sphere.mat');

% Select two dipolar sources in the volume
sources = where_heuristic(model, 'position','leftAndRight', 'howMany', 2);

% create a data vector, activate the left source
s1 = zeros(1,size(model.A,2));
s1(sources(1)) = 1;

% get the surface measurements
x1 = model.forward_transform(s1);

% reconstruct sources
shat1 = sLORETA(model.A, x1', true);

% sort by strength 
[~,sIdx1]=sort(abs(shat1),'descend');

% display
figure(1);
subplot(2,2,1);
model.visualize(sources(1));
title('True left alone');
subplot(2,2,2);
model.visualize(sIdx1(1));
title('Localized left');

% what if we have two sources active at the same time?
s2 = zeros(1,size(model.A,2));
s2(sources(1:2)) = 1;
x2 = model.forward_transform(s2);
shat2 = sLORETA(model.A, x2', true);

% display
% oups, sloreta doesn't do so well!
[~,sIdx2]=sort(abs(shat2),'descend');
subplot(2,2,3);
model.visualize(sources);
title('True left and right together');
subplot(2,2,4);
model.visualize(sIdx2(1:20));
title('Localized 20 strongest');

