
% LDA vs Quadratic LDA

clear; close all;

X = [randn(5000,2)-0; 3.*rand(5000,2) + 0];
labels = [repmat(1,[5000 1]); repmat(2,[5000, 1])];

figure();
plot(X(:,1),X(:,2),'.');

pSpec.classifierParams.type = 'lda';
pSpec.classifierParams.tikhonov = 0;
pSpec.classifierParams.shrink = 0;
pSpec.classifierParams.quadratic = false;
pSpec.numberClasses = 2;

model1 = lda_train(X, labels, pSpec);

pSpec.classifierParams.type = 'lda';
pSpec.classifierParams.tikhonov = 0;
pSpec.classifierParams.shrink = 0;
pSpec.classifierParams.quadratic = true;
pSpec.numberClasses = 2;

model2 = lda_train(X, labels, pSpec);

Xg = 50*(rand(10000,2)-0.5);

[pred1,raw1] = lda_test(model1.modelClassifier, X);
[pred2,raw2] = lda_test(model2.modelClassifier, X);
[pred1g,raw1g] = lda_test(model1.modelClassifier, Xg);
[pred2g,raw2g] = lda_test(model2.modelClassifier, Xg);

figure(); clf;

subplot(2,2,1); hold on;
plot(X(pred1==1,1),X(pred1==1,2),'r.');
plot(X(pred1~=1,1),X(pred1~=1,2),'g.');

subplot(2,2,2); hold on;
plot(X(pred2==1,1),X(pred2==1,2),'r.');
plot(X(pred2~=1,1),X(pred2~=1,2),'g.');

subplot(2,2,3); hold on;
plot(Xg(pred1g==1,1),Xg(pred1g==1,2),'r.');
plot(Xg(pred1g~=1,1),Xg(pred1g~=1,2),'g.');

subplot(2,2,4); hold on;
plot(Xg(pred2g==1,1),Xg(pred2g==1,2),'r.');
plot(Xg(pred2g~=1,1),Xg(pred2g~=1,2),'g.');

