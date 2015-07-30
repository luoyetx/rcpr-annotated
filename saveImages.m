function saveImages(dataset)
% load mat
data = sprintf('data/%s.mat', dataset);
load(data);
mkdir('data', dataset);
if ~exist('IsTr', 'var')
    IsTr = IsT;
    phisTr = phisT;
end
% save images
for i = 1:length(IsTr)
    fprintf('write %d\n', i);
    fname = sprintf('data/%s/%04d.jpg', dataset, i);
    imwrite(IsTr{i}, fname);
end
% save landmarks
for i = 1:length(phisTr)
    fname = sprintf('data/%s/%04d.pts', dataset, i);
    fd = fopen(fname, 'w');
    fprintf(fd, 'version: 1\n');
    fprintf(fd, 'n_points: 29\n');
    fprintf(fd, '{\n');
    for j = 1:29
        fprintf(fd, '%d %d\n', phisTr(i, j), phisTr(i, j+29));
    end
    fprintf(fd, '}\n');
    fclose(fd);
end
end