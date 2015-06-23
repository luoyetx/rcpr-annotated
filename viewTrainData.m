function viewTrainData()
% 查看训练数据
load('data/COFW_train.mat');
output = 'data/trainImages';
n = size(IsTr, 1);
for i=1:n
    fprintf('write data %d\n', i);
    bbox = bboxesTr(i, :);
    img = IsTr{i};
    phis = phisTr(i, :);
    name = sprintf('%s/%04d.jpg', output, i);
    imwrite(img, name);
    name = sprintf('%s/%04d.txt', output, i);
    f = fopen(name, 'w');
    fprintf(f, '%d %d %d %d', bbox(1), bbox(2), bbox(3), bbox(4));
    for j=1:size(phis, 2)
        fprintf(f, ' %f', phis(1, j));
    end
    fprintf(f, '\n');
    fclose(f);
end
end

