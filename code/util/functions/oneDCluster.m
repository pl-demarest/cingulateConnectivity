function [clusterDataOut] = oneDCluster(data,k,plotting,randomNumber,optimizationMethod,silouetteThreshold,region)
% specifcy plotting = subplot for a subplot of each clustering result
% anything else will result in individual figures

if k > length(data)
    k = length(data);
end

rng(randomNumber)
clusterDataOut(k).cluster = [];
clusterDataOut(k).errorType = {};
clusterDataOut(k).error = [];
clusterDataOut(k).labels = {};
clusterDataOut(k).centroids = {};
clusterDataOut(k).silhouette = {};
[r, c] = getSubplotDimensions(k);

if strcmp(plotting,'subplot') == 1
figure('Name','');
end

for mainCluster = 1:k

clusterDataOut(mainCluster).cluster = mainCluster;


[clusters, centroids] = kmeans(data', mainCluster,'MaxIter',500,'Replicates',3);

clusterDataOut(mainCluster).labels = clusters;
clusterDataOut(mainCluster).centroids = centroids;


%should probably make a funciton specific for colors...
colors = [
    143, 82, 182; % Original Purple
    82, 182, 143; % Green
    182, 143, 82; % Orange
    182, 82, 143; % Pink
    82, 143, 182; % Sky Blue
    69, 185, 214; % Original Cyan/Teal
    185, 69, 214; % Magenta
    214, 185, 69; % Gold/Yellow
    185, 214, 69; % Lime Green
    214, 69, 185; % Hot Pink
    255, 0, 0;    % Pure Red
    0, 255, 0;    % Pure Green
    0, 0, 255;    % Pure Blue
    255, 255, 0;  % Yellow
    0, 255, 255;  % Aqua
    255, 0, 255;  % Magenta
    128, 0, 0;    % Dark Red
    0, 128, 0;    % Dark Green
    0, 0, 128;    % Dark Blue
    128, 128, 0   % Olive
    143, 82, 182; % Original Purple
    82, 182, 143; % Green
    182, 143, 82; % Orange
    182, 82, 143; % Pink
    82, 143, 182; % Sky Blue
    69, 185, 214; % Original Cyan/Teal
    185, 69, 214; % Magenta
    214, 185, 69; % Gold/Yellow
    185, 214, 69; % Lime Green
    214, 69, 185; % Hot Pink
    255, 0, 0;    % Pure Red
    0, 255, 0;    % Pure Green
    0, 0, 255;    % Pure Blue
    255, 255, 0;  % Yellow
    0, 255, 255;  % Aqua
    255, 0, 255;  % Magenta
    128, 0, 0;    % Dark Red
    0, 128, 0;    % Dark Green
    0, 0, 128;    % Dark Blue
    128, 128, 0 
];

colors = colors./255;
% Sort the data
uniqueLabels = unique(clusters);

clusterDataOut(mainCluster).silhouette = silhouette(data',clusters);




%figure('Name',['Siloutette Score k=' num2str(mainCluster)]);
%silhouette(data',clusters)


if strcmp(plotting,'subplot') == 1
subplot(r,c,mainCluster)
else
figure('Name',['k=' num2str(mainCluster) 'Distribution'],'position',[452         697        1157         297]);
end


for cluster = 1:length(uniqueLabels)

currentData = data(find(clusters == uniqueLabels(cluster)));
scatterDistribution1D(currentData,data,.1,.3,colors(cluster,:))

end
xlabel('Cohen''s D');
set(gca,'ytick',[]);
set(gca,'ycolor','none')
box off
saveas(gcf,['figures/clustering/k=' num2str(mainCluster) region 'Distribution.png'])
saveas(gcf,['figures/clustering/k=' num2str(mainCluster) region 'Distribution.svg'])
end



figure('name','k optimization','position',[ 1427         589         446         541]);
for error = 1:k

switch optimizationMethod

    case 'mean'
        optData = mean(clusterDataOut(error).silhouette);
    case 'median'
        optData = median(clusterDataOut(error).silhouette);
    case 'percentage'
        optData = length(find(clusterDataOut(error).silhouette >= silouetteThreshold))/length(clusterDataOut(error).silhouette);


end
optDataStore(error) = optData;
clusterDataOut(error).error = optData;
clusterDataOut(error).errorType = optimizationMethod;
end
errors = 1:k;



plot(errors,optDataStore,'-o','color','k','MarkerFaceColor','k','LineWidth',2)
box off
hold on

xlabel('Clusters')
ylabel('Silouette Score (% > 0.8)')

saveas(gcf,['figures/clustering/kmeansOptimizationSig' region '.png'])
saveas(gcf,['figures/clustering/kmeansOptimizationSig' region '.svg'])

end
