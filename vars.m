% 本文件就 RCPR 中统一的变量命名做出相应的解释

% T 模型迭代次数
% K 每次迭代中随机厥的个数
% L 训练时，真实形状携带的初始形状个数
% RT1 测试时初始形状的个数

% N 训练数据个数
% D 特征点(形状)维数 (X, Y, V)，数据可能不带有V
% model 数据集的配置，包括数据集名称，特征点个数等
% pGt 真实形状 size=[N, D]
% pGtN 相对形状
% pCur 当前的真实形状
% posInit 训练数据人脸框位置

% ftrs 特征值（两个特征点之差）
% ftrPos 用于计算特征值的特征配置，包括直线的两个顶点和特征点相对于中点的偏置，都在 xz 中
% ftrPrm 随机产生特征时的配置，包括待选特征集合的个数，通道数和偏置的振幅？

% 与遮挡相关的变量
% occlD
%   featOccl    每个特征点所在区域的遮挡度
%   group       每个特征点所在的区域
% groupF    每个人脸关键点所在的区域
% occl      每个人脸关键点的遮挡度
% occlAm    每块区域中人脸关键点的遮挡度之和（这些关键点落在了这块区域中）
% ftrsOccl  随机厥用到的所有特征点所在区域遮挡度之和
%
% *****多级并联回归器的加权求和*****
%   考虑 3 个回归器的遮挡度为 o1, o2, o3
%   w_ = 1 - normalize(o) % normalize(o) = (o_i - o_min) / (o_max - o_min)
%   w_sum = sum(w_)
%   w = w_ / w_sum % 如果 w_sum = 0（即 o1=o2=o3） 那么 w = 1 / 3

% ******************regModel 说明**************************
% regModel.model    记录了训练用的数据集的配置说明
%       model.nfids     关键点个数
%       model.D         形状的维数，nfids*2 || nfids*3
% regModel.pStar    平均相对形状
% regModel.T        整个迭代次数
% regModel.pGtN     所有训练数据的相对形状
% regModel.pDstr    所有训练数据的真实形状
%
% regModel.regs.regInfo 所有回归器参数
%       regInfo.ysFern      记录了随机厥叶节点的形状增量
%       regInfo.thrs        随机厥没错节点的阈值
%       regInfo.fids        2xM，记录了选择的特征集合点的编号，两个点所在像素值相减便是特征值
%       假设随机厥深度为 M，则 ysFern 中记录了 2^M 中形状增量
%       根据 fids 中的编号计算出 M 个值与 thrs 阈值比较得到 M 位二进制数
%       根据这 M 为二进制数从 ysFern 中查询到形状增量
% regModel.regs.ftrPos 记录了所有随机厥中特征选取方式
%       ftrPos.xs           记录了两个人脸关键点和其中点的偏置（这三个数据可以计算出一个点，组成待选特征点集合）
%       ftrPos.F            待选特征点集合的大小
%       nChn                图像的通道数
%
% regModel.th       ？？


% functions
%
% shapeGt('inverse',model,pCur,bboxes)
% 将形状投影到人脸框上，真实形状到相对形状
% pCur 为真实形状，bboxes 为人脸框
% 返回相对形状
%
% shapeGt('compose',model,pTar,pGt,bboxes)
% 将真实形状加到相对形状上，先投影真实形状
% pTar 为相对形状，pGt 为真实形状，bboxes 为真实形状所投影的人脸框
% 返回两个形状相加的结果，为相对的形状
%
% shapeGt('ftrsGenDup',model,ftrPrm)
% 根据配置生成随机厥的待选特征集合
% ftrPrm 配置了特征集合的参数，包括特征个数，linepoint特征的配置，详见论文中对特征的描述
% 返回待选特征集合
%
% getLinePoint(ftrData.xs,pStar(1:nfids),pStar(nfids+1:nfids*2))
% 计算用于表示特征的点
% xs 记录了直线的两个顶点编号，后接 x,y 坐标
% 返回用于计算特征的点的坐标
% 