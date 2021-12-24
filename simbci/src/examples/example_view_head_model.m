
clear; close all;

model = core_head('filename', 'sabre:/models/leadfield-sphere.mat');

% Display source dipoles and electrodes
subplot(1,3,1);
model.visualize();
title('Head model');

% Display two highlighted dipolar sources
sources = where_heuristic(model,'position','leftAndRight', 'howMany',2);
subplot(1,3,2);
model.visualize(sources);
title('Heuristic left and right');

% Display two highlighted dipolar sources
%sources1 = roi_heuristic(model,'position','leftAndRight', 'howMany',2,'delta',[0 0 0]);
%sources2 = roi_heuristic(model,'position','leftAndRight', 'howMany',2,'delta',[0 0 -25]);
%figure(3);
%model.visualize([sources1,sources2]);

% Display four highlighted dipolar sources

sources = where_heuristic(model,'position','rightCluster', 'howMany', 4, 'dipolesBetweenSources', 1);
subplot(1,3,3);
model.visualize(sources);
title('Strip of 4 soures');
