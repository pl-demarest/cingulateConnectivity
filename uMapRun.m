clear all
addpath(genpath(cd))

%%
load('data/compiledDataMatrix.mat');
load('data/compiledData.mat');

labels = fieldnames(data);

%%
takeMat = dataMat(:,[2:21,23:27,29:30]);

labelsID = dataMat(:,31);


takeMat(isnan(takeMat)) = 0;

responseIDX = (dataMat(:,1) < 0.000001);
 takeMat = rescaleMatrixDimension(takeMat, [0,1], 2);
[reduction, umap, clusterIdentifiers, extras]=run_umap(takeMat);

%%
sigOnly = takeMat(responseIDX,:);
sigOnly(isnan(sigOnly)) = 0;

sigOnly = rescaleMatrixDimension(sigOnly, [0,1], 2);
[reduction, umap, clusterIdentifiers, extras]=run_umap(sigOnly);

%%

umapxR =  reduction(responseIDX,1);
umapyR = reduction(responseIDX,2);

umapx =  reduction(~responseIDX,1);
umapy = reduction(~responseIDX,2);

figure();
scatter(umapx,umapy,'MarkerFaceColor','k','MarkerEdgeColor','none','MarkerFaceAlpha',0.35);
hold on
scatter(umapxR, umapyR,'MarkerFaceColor','r','MarkerEdgeColor','none','MarkerFaceAlpha',0.35);


%%
colors = getColors('rainbow matrix');
pairs = [1,2;3,4;5,6];
indexes = labelsID(responseIDX);

figure;
for i = 1:6
curIDX =  indexes == i;
scatter(reduction(curIDX,1),reduction(curIDX,2),'MarkerFaceColor',colors(i,:),'MarkerEdgeColor','none','MarkerFaceAlpha',0.35)
hold on
end

%% do PCA and correlation analysis

rho = corr(sigOnly);

%%
figure;
h = heatmap(rho);
colorbar
clim([-1 1])
colormap(flip(brewermap([] ...
    ,'RdBu')));
h.XDisplayLabels = labels([2:21,23:27,29:30]);
h.YDisplayLabels = labels([2:21,23:27,29:30]); 
set(gca,'FontSize',20)

%% pca

[coeff,score,latent,tsquared,explained,mu] = pca(sigOnly);

figure()
scatter3(score(:,1),score(:,2),score(:,3),'MarkerFaceColor','k','MarkerEdgeColor','none')
xlabel('PC1')
ylabel('PC2')
zlabel('PC3')
set(gca,'FontSize',20)

figure;
h = heatmap(coeff(:,1:3));
colormap(flip(brewermap([] ...
    ,'RdBu')));
clim([-1 1])
h.YDisplayLabels = labels([2:21,23:27,29:30]);
set(gca,'FontSize',20)