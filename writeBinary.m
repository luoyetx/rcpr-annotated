function writeBinary(model_path)
% 将模型数据以二进制方式写入文件中，方便其他语言调用
%   model_path 为模型文件名，目录在 models 下面
outfile = 'models/model.bin';
load(model_path);
fd = fopen(outfile, 'wb'); % overwrite if exists

% 写入模型基本配置
T = regModel.T;
[regSize, fernSize] = size(regModel.regs(1).regInfo);
landmarkSize = regModel.model.nfids;
landmarkDim = regModel.model.D;
M = size(regModel.regs(1).regInfo{1, 1}.thrs, 2);
featureSize = regModel.regs(1).ftrPos.F;
N = size(regModel.pGtN,1);
fwrite(fd, T, 'int32');
fwrite(fd, regSize, 'int32');
fwrite(fd, fernSize, 'int32');
fwrite(fd, landmarkSize, 'int32');
fwrite(fd, landmarkDim, 'int32');
fwrite(fd, M, 'int32');
fwrite(fd, featureSize, 'int32');
fwrite(fd, N, 'int32');

% 写入平均形状
for i=1:landmarkDim
    fwrite(fd, regModel.pStar(1, i), 'float32');
end
% 写入训练时的形状
for i=1:N
    for j=1:landmarkDim
        fwrite(fd, regModel.pGtN(i, j), 'float32');
    end
end

% 写入模型参数
for i=1:T
    fprintf('正在写入第 %i 级回归器参数\n', i)
    % 先写入特征池 id1, id2, t1
    % 选择的特征编号，分成两行，我们令编号从 0 开始
    xs = regModel.regs(i).ftrPos.xs;
    for j=1:featureSize
        % 关键点编号从 0 开始
        fwrite(fd, xs(j, 1)-1, 'int32');
        fwrite(fd, xs(j, 2)-1, 'int32');
        fwrite(fd, xs(j, 3), 'float32');
    end
    % 写入随机厥参数 15x3
    for r=1:regSize
        for c=1:fernSize
            reg = regModel.regs(i).regInfo{r, c};
            % 选择的特征编号，分成两行，我们令编号从 0 开始
            for m=1:M
                fwrite(fd, reg.fids(1, m)-1, 'int32');
            end
            for m=1:M
                fwrite(fd, reg.fids(2, m)-1, 'int32');
            end
            % 特征值阈值
            for m=1:M
                fwrite(fd, reg.thrs(1, m), 'float32');
            end
            % 随机厥叶节点的形状增量
            for k=1:2^M
                for p=1:landmarkDim
                    fwrite(fd, reg.ysFern(k, p), 'float32');
                end
            end
        end
    end
end

% 关闭文件
fclose(fd);
end

