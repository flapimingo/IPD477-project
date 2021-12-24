%
% Tests glmnet with very simple data to see its basically working
%
clear;
close all;

addpath('packages/glmnet_matlab');

xTrain=randn(2500,5000);
xTest=randn(10000,5000);

%y1=round(rand(100,1));
%fit1=cvglmnet(x1,y1,'binomial');

yTrain=(xTrain(:,1)>0)*2-1;
yTest=(xTest(:,1)>0)*2-1;

fit2=cvglmnet(xTrain,yTrain,'binomial', [], 'class');
find(abs(cvglmnetCoef(fit2))>0)'

yTrainHat = cvglmnetPredict(fit2, xTrain, [], 'class');
yTestHat = cvglmnetPredict(fit2, xTest, [], 'class');

trainAcc = mean(yTrainHat == yTrain);
testAcc = mean(yTestHat == yTest);

fprintf(1,'Train acc %f, test acc %f\n', trainAcc, testAcc);

%y3=x1(:,1);
%fit3=cvglmnet(x1,y3);
%find(abs(cvglmnetCoef(fit3))>0)


