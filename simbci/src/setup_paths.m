
% The purpose of this global variable is to help scripts loading stuff from
% the default locations even when the user has cd'd elsewhere.
global SABRE_BASE_DIR;

SABRE_BASE_DIR = sprintf('%s/../', pwd());

% Main components developed mostly at INRIA
addpath(sprintf('%s/src/', SABRE_BASE_DIR));
addpath(sprintf('%s/src/config', SABRE_BASE_DIR));
addpath(sprintf('%s/src/core', SABRE_BASE_DIR));
addpath(sprintf('%s/src/utils', SABRE_BASE_DIR));
addpath(sprintf('%s/src/when', SABRE_BASE_DIR));
addpath(sprintf('%s/src/what', SABRE_BASE_DIR));
addpath(sprintf('%s/src/where', SABRE_BASE_DIR));
addpath(sprintf('%s/src/classifiers', SABRE_BASE_DIR));
addpath(sprintf('%s/src/extractors', SABRE_BASE_DIR));
addpath(sprintf('%s/src/tests', SABRE_BASE_DIR));
addpath(sprintf('%s/src/visualizers', SABRE_BASE_DIR));

% Contributions from CERL @ IMT Atlantique
addpath(sprintf('%s/contrib/cerl-imt/processors', SABRE_BASE_DIR));
addpath(sprintf('%s/contrib/cerl-imt/utils', SABRE_BASE_DIR));
addpath(sprintf('%s/contrib/cerl-imt/inverse_algorithms', SABRE_BASE_DIR));

% Misc inverse algorithms
addpath(sprintf('%s/contrib/inverse_algorithms', SABRE_BASE_DIR));
addpath(sprintf('%s/contrib/inverse_algorithms/details', SABRE_BASE_DIR));

% Third party packages or their parts that the system may use
addpath(sprintf('%s/contrib/packages/bcilab', SABRE_BASE_DIR));						% Components from BCILAB
addpath(sprintf('%s/contrib/packages/glmnet_matlab', SABRE_BASE_DIR));               % Feature selection by Generalized Linear Models & Lasso
addpath(sprintf('%s/contrib/packages/liblinear-2.1/windows', SABRE_BASE_DIR));       % Feature selection by L1 SVM. For non-windows platforms, needs a compile
addpath(sprintf('%s/contrib/packages/eeglab_ica/', SABRE_BASE_DIR));			  	    % Infomax Independent Component Analysis from the EEGLAB package
addpath(sprintf('%s/contrib/colormaps', SABRE_BASE_DIR));

