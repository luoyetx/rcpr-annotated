% Copyright 2013 X.P. Burgos-Artizzu, P.Perona and Piotr Dollar.  
%  [xpburgos-at-gmail-dot-com]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Simplified BSD License [see bsd.txt]
%
%  Please cite our paper if you use the code:
%  Robust face landmark estimation under occlusion, 
%  X.P. Burgos-Artizzu, P. Perona, P. Dollar (c)
%  ICCV'13, Sydney, Australia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For pre-requisites and compilation, see CONTENTS.m
%
% This code trains and tests RCPR on COFW dataset. 
%  COFW is composed of two files (data/COFW_train.mat, data/COFW_test.mat) 
%  which contain:  
%    -phisTr,phisT - ground truth shapes (train/test)
%    -IsTr,IsT - images (train/test)
%    -bboxesTr, bboxesT - face bounding boxes (train/test)
%  If you change path to folder containing training/testing files, change
%  this variable here:
COFW_DIR='./data/';


% global configure
dataset_type = 'five'; % cofw, lfpw, five
cpr_type=2;
T=100;K=30;L=20;RT1=5;F=20;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD COFW dataset
% training/testing images and ground truth

% This should be 'cofw' for 29 landmarks or 'five' for 5 landmarks
%dataset_type = 'lfw';

if strcmp(dataset_type, 'cofw')
    trFile=[COFW_DIR 'COFW_train.mat'];
    testFile=[COFW_DIR 'COFW_test.mat'];
elseif strcmp(dataset_type, 'five')
    trFile=[COFW_DIR 'FIVE_train.mat'];
    testFile=[COFW_DIR 'FIVE_test.mat'];
elseif strcmp(dataset_type, 'lfpw')
    trFile=[COFW_DIR 'LFPW_train.mat'];
    testFile=[COFW_DIR 'LFPW_test.mat'];  
else
    dataset_type='cofw';
    trFile=[COFW_DIR 'COFW_train.mat'];
    testFile=[COFW_DIR 'COFW_test.mat'];
end
% Load files
% Is 表示图像
% bboxes 表示人脸框在图像 Is 中的位置
% phis 表示特征点在图像 Is 中的位置
load(trFile,'phisTr','IsTr','bboxesTr');bboxesTr=round(bboxesTr);
load(testFile,'phisT','IsT','bboxesT');bboxesT=round(bboxesT);
% nfids 表示特征点个数
nfids=size(phisTr,2)/3;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET UP PARAMETERS
%Choose algorithm to use
% cpr_type=1 (reimplementation of Cao et al.)
% cpr_type=2 RCPR (features+restarts)
% cpr_type=3 RCPR (full)
%cpr_type=2;

% 迭代 T 次，每次采用 K 个随机厥
% 训练时，每个人脸用 L 的形状初始化来训练
% 测试时用 RT1 个形状来初始化
% T=100;K=50;L=20;RT1=5;
if(cpr_type==1)
    % 我们不会用到这种类型的特征
    %Remove occlusion information
    phisTr=phisTr(:,1:nfids*2);phisT=phisT(:,1:nfids*2);
    %Create LFPW model (29 landmarks without visibility)
    model = shapeGt('createModel','lfpw');
    %CPR for face PARAMETERS (Cao et al. CVPR12)
    %(type 2, points relative to closest landmark)
    %T=100;K=50;L=20;RT1=5;
    %ftrPrm = struct('type',2,'F',400,'nChn',1,'radius',1);
    ftrPrm = struct('type',2,'F',F,'nChn',1,'radius',1);
    prm=struct('thrr',[-1 1]/5,'reg',.01);
    occlPrm=struct('nrows',3,'ncols',3,'nzones',1,'Stot',1,'th',.5);
    regPrm = struct('type',1,'K',K,'occlPrm',occlPrm,...
        'loss','L2','R',0,'M',5,'model',model,'prm',prm);
    prunePrm=struct('prune',0,'maxIter',2,'th',0.1,'tIni',10);
elseif(cpr_type==2)
    % 不使用遮挡信息
    %Remove occlusion information
    phisTr=phisTr(:,1:nfids*2);phisT=phisT(:,1:nfids*2);
    %Create LFW model (5 landmarks without visibility)
    model = shapeGt('createModel',dataset_type);
    %RCPR(features+restarts) PARAMETERS
    %(type 4, points relative to any 2 landmarks)
    %T=100;K=50;L=20;RT1=5;
    %ftrPrm = struct('type',4,'F',400,'nChn',1,'radius',1.5);
    ftrPrm = struct('type',4,'F',F,'nChn',1,'radius',1.5);
    prm=struct('thrr',[-1 1]/5,'reg',.01);
    occlPrm=struct('nrows',3,'ncols',3,'nzones',1,'Stot',1,'th',.5);
    regPrm = struct('type',1,'K',K,'occlPrm',occlPrm,...
        'loss','L2','R',0,'M',5,'model',model,'prm',prm);
    %smart restarts are enabled
    prunePrm=struct('prune',1,'maxIter',2,'th',0.1,'tIni',10);
    %remove occlusion information
    phisTr=phisTr(:,1:nfids*2);phisT=phisT(:,1:nfids*2);
elseif(cpr_type==3)
    %Create COFW model (29 landmarks including visibility)
    model = shapeGt('createModel',dataset_type);
    %RCPR (full) PARAMETERS
    %(type 4, points relative to any 2 landmarks)
    %T=100;K=15;L=20;RT1=5;
    % 设置随机厥参数
    % 随机产生 400 个特征点
    %ftrPrm = struct('type',4,'F',400,'nChn',1,'radius',1.5);
    ftrPrm = struct('type',4,'F',F,'nChn',1,'radius',1.5);
    prm=struct('thrr',[-1 1]/5,'reg',.01);
    %Stot=3 regressors to perform occlusion weighted median
    % 遮挡相关阐述，将人脸划分为 3x3，采用 Stot=3 个回归器并联预测，结果加权求和
    occlPrm=struct('nrows',3,'ncols',3,'nzones',1,'Stot',3,'th',.5);
    regPrm = struct('type',1,'K',K,'occlPrm',occlPrm,...
        'loss','L2','R',0,'M',5,'model',model,'prm',prm);
    %smart restarts are enabled
    prunePrm=struct('prune',1,'maxIter',2,'th',0.1,'tIni',10);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TRAIN
%Initialize randomly L shapes per training image
% pCur arguement过的真实初始形状
% pGt arguement过的真实形状
% pGtN arguement过的相对形状
% pStar 平均相对形状
% imgIds arguement用到了图片序列
% N arguement过后的训练样本数
% N1 真实训练样本数
[pCur,pGt,pGtN,pStar,imgIds,N,N1]=shapeGt('initTr',...
    IsTr,phisTr,model,[],bboxesTr,L,10);
initData=struct('pCur',pCur,'pGt',pGt,'pGtN',pGtN,'pStar',pStar,...
    'imgIds',imgIds,'N',N,'N1',N1);
%Create training structure
trPrm=struct('model',model,'pStar',[],'posInit',bboxesTr,...
    'T',T,'L',L,'regPrm',regPrm,'ftrPrm',ftrPrm,...
    'pad',10,'verbose',1,'initData',initData);
%Train model
[regModel,~] = rcprTrain(IsTr,phisTr,trPrm);

% 保存模型
regPrm = trPrm.regPrm;
save('./models/rcpr.mat', 'regModel', 'regPrm', 'prunePrm');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TEST
%Initialize randomly using RT1 shapes drawn from training
p=shapeGt('initTest',IsT,bboxesT,model,pStar,pGtN,RT1);
%Create test struct
testPrm = struct('RT1',RT1,'pInit',bboxesT,...
    'regPrm',regPrm,'initData',p,'prunePrm',prunePrm,...
    'verbose',1);
%Test
t=clock;[p,pRT] = rcprTest(IsT,regModel,testPrm);t=etime(clock,t);
%Round up the pixel positions
p(:,1:nfids*2)=round(p(:,1:nfids*2));
% If rcpr_type=3, use threshold computed during training to 
% binarize occlusion
if(cpr_type==3)
    occl=p(:,(nfids*2)+1:end);
    occl(occl>=regModel.th)=1;occl(occl<regModel.th)=0;
    p(:,(nfids*2)+1:end)=occl;
end
%Compute loss
loss = shapeGt('dist',regModel.model,p,phisT);
fprintf('--------------DONE\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DISPLAY Standard histogram of errors
figure(1),clf,
mu1=mean(loss(loss<0.1));muAll=mean(loss);
fail=100*length(find(loss>0.1))/length(loss);
bins=log10(min(loss)):0.1:log10(max(loss));ftsz=20;
[n,b]=hist(log10(loss),bins); n=n./sum(n);
semilogx(10.^b,n,'b','LineWidth',3);
hold on,plot(zeros(10,1)+2.5,linspace(0,max(n),10),'--k');
ticks=[0 linspace(min(loss),max(loss)/4,5) ...
    linspace((max(loss)/3),max(loss),3)];
ticks=round(ticks*100)/100;
set(gca,'XTick',ticks,'FontSize',ftsz);
xlabel('error','FontSize',ftsz);ylabel('probability','FontSize',ftsz),
title(['Mean error=' num2str(muAll,'%0.2f') '   ' ...
    'Mean error (<0.1)=' num2str(mu1,'%0.2f') '   ' ...
    'Failure rate (%)=' num2str(fail,'%0.2f')],'FontSize',ftsz);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% VISUALIZE Example results on a test image
figure(3),clf,
nimage=12;
%Ground-truth
subplot(1,2,1),
shapeGt('draw',model,IsT{nimage},phisT(nimage,:),{'lw',20});
title('Ground Truth');
%Prediction
subplot(1,2,2),shapeGt('draw',model,IsT{nimage},p(nimage,:),...
    {'lw',20});
title('Prediction');