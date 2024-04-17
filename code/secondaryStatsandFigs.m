load(['data/processed/data.mat'])
numChans = size(data.PCCMain.SixmA,1);
% get coden's d value and variance value for each channel
cohDACC = nan(1,size(data.ACCMain.SixmA,1));
cohDPCC = nan(1,size(data.PCCMain.SixmA,1));

%calculate the p-val for each distribution
pValACC = nan(1,size(data.ACCMain.SixmA,1));

PCCDisVar = nan(1,numChans);
ACCDisVar = nan(1,numChans);
ch2plot = find(contains(VERA.labels, 'ctx-rh-isthmuscingulate'));
%%
figure;
[rows,columns,channelNumber] = getSubplotDimensions(numChans);

set(0,'DefaultFigureWindowStyle','docked')


for ch = 1:size(data.ACCMain.SixmA,1)

    baselineACCDist = squeeze(data.ACCCoherence.baseline(ch,ch,:));
    baselinePCCDist = squeeze(data.PCCCoherence.baseline(ch,ch,:));

    taskACCDist = squeeze(data.ACCCoherence.task(ch,ch,:));
    taskPCCDist = squeeze(data.PCCCoherence.task(ch,ch,:));

    cohDACC(ch) = computeCohenD(taskACCDist,baselineACCDist,'paired');
    cohDPCC(ch) = computeCohenD(taskPCCDist,baselinePCCDist,'paired');

    PCCDisVar(ch) = nanvar(taskPCCDist);
    ACCDisVar(ch) = nanvar(taskACCDist);

    pValACC(ch) = ranksum(taskACCDist,baselineACCDist);
    pValPCC(ch) = ranksum(taskPCCDist,baselinePCCDist);

subplot(rows, columns, ch)

histogram(baselineACCDist,25,'FaceColor','k','FaceAlpha',0.5)
hold on
if ismember(ch,ch2plot) == 1
    hColor = [1,0,0];
else
    hColor = ACCColor;
end

histogram(taskACCDist,25,'FaceColor',hColor,'FaceAlpha',0.5)
title(num2str(cohDACC(ch)))

end


%FDR of the pVals
[FDRACC] = mafdr(pValACC,'BHFDR',true);
[FDRPCC] = mafdr(pValPCC,'BHFDR',true);
%% make size of electrodes correspond to coh's D
normSize = cohDPCC();
normSize(normSize < 0) = min(normSize(normSize > 0));

radiusMin = min(normSize);
radiusMax = max(normSize);

stepSize = (radiusMax-radiusMin)/10;

legendRadii = ([radiusMin:stepSize:radiusMax]+0.5)*1.1;

figure('color','white','Position',[1000         243        1304        1095]);


surf = plot3DModel(gca,VERA.cortex);
surf.FaceColor = [100,126,146]/256;
alpha(0.02)
hold on
for ch = 1:numChans

    if ismember(ch,ch2plot) ==1
        curColor = [1,0,0];

    else
        curColor = PCCColor;
    end
plotBallsOnVolume(gca,VERA.tala.electrodes(ch,:),curColor,((normSize(ch)+0.5)*1.1),'MarkerEdgeColor','k')
hold on

end

xMax = 50;
yMax = 50;
zMax = 0;

for legend = 1:length(legendRadii)

    if legend ~=1
yMax = yMax + legendRadii(legend - 1) + 5;
    end

plotBallsOnVolume(gca,[xMax,yMax,zMax],curColor,legendRadii(legend),'MarkerEdgeColor','k')


end

% view([180 0] )
% saveas(gcf,'figures/cohDACCbrainFront.png')
% 
% view([-93.0402,-1])
% saveas(gcf,'figures/cohDACCbrainSide.png')
% 
% view([-2,90])
% saveas(gcf,'figures/cohDACCbrainTop.png')

view([-494.1925 60.3828] )
saveas(gcf,'figures/cohDPCCbrainDiag.png')

%% make size of electrodes correspond to coh's D
normSize = cohDPCC();
normSize(normSize < 0) = min(normSize(normSize > 0));

figure('color','white','Position',[1000         243        1304        1095]);
surf = plot3DModel(gca,VERA.cortex);
surf.FaceColor = [100,126,146]/256;
alpha(0.02)
hold on
for ch = 1:numChans

    if ismember(ch,PCCStimChans) == 1
        curColor = [1,0,0];

    else
        curColor = PCCColor;
    end
plotBallsOnVolume(gca,VERA.tala.electrodes(ch,:),curColor,(normSize(ch)*1.3))
hold on
end

view([180 0] )
saveas(gcf,'figures/cohDPCCbrainFront.png')

view([-93.0402,-1])
saveas(gcf,'figures/cohDPCCbrainSide.png')

view([-2,90])
saveas(gcf,'figures/cohDPCCbrainTop.png')

view([ -494.1925 60.3828] )
saveas(gcf,'figures/cohDPCCbrainDiag.png')

%%

meanCohDACC = AverageResponseByRegions(cohDACC',unique(VERA.labels),VERA.labels);
meanCohDPCC = AverageResponseByRegions(cohDPCC',unique(VERA.labels),VERA.labels);

meanACCDisVar =AverageResponseByRegions(ACCDisVar',unique(VERA.labels),VERA.labels);
meanPCCDisVar =AverageResponseByRegions(PCCDisVar',unique(VERA.labels),VERA.labels);


% Assuming the variable of values and labels are 'values' and 'labels' respectively
values = meanACCDisVar;
values2 = meanPCCDisVar;% Replace this with your actual values
labels = uniqueLabels; % Replace this with your actual labels

% Create a table from the values and labels
T = table(values, values2, labels, 'VariableNames', {'valuesA', 'valuesP', 'labels'});

% Sort the table by values in descending order
T = sortrows(T, 'valuesA', 'descend');

% Plot the bar chart
figure('position',[ -1426          59        1106        1730]);
hold on;
for i = 1:numel(T.valuesA)

    barh(i, T.valuesP(i), 'FaceColor', PCCGradient{i},'EdgeColor','none'); 
    

end
hold off;
set(gca, 'YDir','reverse'); % To have the largest at the top
set(gca, 'YTick', 1:numel(T.valuesA), 'YTickLabel', T.labels);
set(gca, 'XAxisLocation', 'top'); % To set the x-axis at the top
xlabel('Variance');
set(gca,'TickLength', [0.01 0])
set(gca,'fontsize',18,'FontName','Source Sans Variable')
box off

saveas(gcf,'figures/VarcodDPCCInEachRegion.png')
saveas(gcf,'figures/VarcohDPCCInEachRegion.svg')

%% Exemplar Distributions

TempidxList = find(contains(VERA.labels,'cerebellum'));
Tempidx = 31;

figure;
histogram(data.ACCCoherence.baseline(Tempidx,Tempidx,:),25,'FaceColor','k','FaceAlpha',0.5,'BinWidth',0.025)
hold on
histogram(data.ACCCoherence.task(Tempidx,Tempidx,:),25,'FaceColor',ACCColor,'FaceAlpha',0.5,'BinWidth',0.025)
title('Medial OFC')
xlabel('Spearmans Rho');
box off
ylabel('Count')
ylim([0 60])
yticks([0,20,40,60])
xlim([-.75 1])
text(-0.5,30,['Cohens D = ' num2str(cohDACC(Tempidx))])
set(gca,'fontsize',18,'FontName','Source Sans Variable')

% Exemplar Distributions

figure;
histogram(data.PCCCoherence.baseline(Tempidx,Tempidx,:),25,'FaceColor','k','FaceAlpha',0.5,'BinWidth',0.025)
hold on
histogram(data.PCCCoherence.task(Tempidx,Tempidx,:),25,'FaceColor',PCCColor,'FaceAlpha',0.5,'BinWidth',0.025)
box off
xlim([-.75 1])
ylim([0 60])
yticks([0,20,40,60])
text(-0.5,30,['Cohens D = ' num2str(cohDPCC(Tempidx))])
set(gca,'fontsize',18,'FontName','Source Sans Variable')

%% Clustering effect Sizes

clusteringDataOut = oneDCluster(cohDACC,20,'',40,'percentage',.8);

%See if it makes a difference to cluster only vlaues that have a
%significant deviation from baseline.
%Also, should probably turn the labeling consistency script into a usable
%function such that the same datasets are getting the same labels

%% significance
idx =  (pValACC<.05/230) & (FDRACC < 0.01);
idx2 = find((pValACC>=0.01 & FDRACC >= 0.01));
sigColors = [1,0,0;0,0,0];
figure('position',[452         697        1157         297]);
for group = 1:2

    if group == 1
currentData = cohDACC(idx);
    else
currentData = cohDACC(~idx);
    end

scatterDistribution1D(currentData,cohDACC,.1,.3,sigColors(group,:))

end
xlabel('Cohen''s D');
set(gca,'ytick',[]);
set(gca,'ycolor','none')
box off

% saveas(gcf,'figures/pipelineGenerationPreliminaryFigures/significantChans.png')
% saveas(gcf,'figures/pipelineGenerationPreliminaryFigures/significantChans.svg')


figure('position',[452         697        1157         297]);
scatterDistribution1D(cohDACC,cohDACC,.1,.3,[0,0,0])
xlabel('Cohen''s D');
set(gca,'ytick',[]);
set(gca,'ycolor','none')
box off
% saveas(gcf,'figures/pipelineGenerationPreliminaryFigures/allChans.png')
% saveas(gcf,'figures/pipelineGenerationPreliminaryFigures/allChans.svg')

%% cluster only significant effect sizes

set(0,'DefaultFigureWindowStyle','default')
clusteringDataOut = oneDCluster(cohDACC(idx),20,'',40,'percentage',.8);



%%

%For this part, eventually, I want to describe the representaiton of unique
%channels across my clusters. I should converge on the optimal number of
%clusters, but for now, we will just use the manual findings- ie optimal
%clusters = 7.

dataOfInterest = clusteringDataOut(5).labels;

uniqueClust = unique(dataOfInterest);

sigIDX = find(idx == 1);
sigLabels = VERA.labels(sigIDX);

for cluster = 1:length(uniqueClust)
    Clusteridx = find(dataOfInterest == uniqueClust(cluster));
        Chanlabel{cluster} = {sigLabels{Clusteridx}}';
end

regionalRepresentation = getRegionsInClusters(Chanlabel,'true');

%% Visualize Responses by Cluster

sigResponses = data.lpZScoreACC.SixmA(idx,:,:);
length_samples = 3800;
% Sampling rate
fs = sr; % Hz, samples per second
% Create time vector
timeVector = (0:length_samples-1) / fs;
timeVector = (timeVector - max(timeVector)/2)*1000;
showIndTrials = 0; %set equal to 1 if plot each individual trial


for cluster = 1:length(uniqueClust)
Clusteridx = find(dataOfInterest == uniqueClust(cluster));
curData = sigResponses(Clusteridx,:,:);

meanData = squeeze(mean(nanmean(curData,3),1));
stdData = squeeze(std(nanstd(curData,0,3),0,1));

figure('Name',['Resposses Cluster' num2str(uniqueClust(cluster))],'Position',[2187         283         457         807])

plot([0 0], [-20 20],'--','color','r','linewidth',2)   
hold on

if showIndTrials == 1
for ch = 1:size(curData,1)
for trial = 1:size(curData,3)


plot(timeVector,curData(ch,:,trial),'Color',[0.5,0.5,0.5,0.1],'linewidth',.75);
hold on

end

end
end


plot(timeVector,meanData,'Color',colors(cluster,:)/255,'LineWidth',4)
hold on
jbfill(timeVector, meanData+stdData,meanData-stdData, colors(cluster,:)/255,colors(cluster,:)/255, 1, 0.2);
ylabel('z-Score')
xlabel('time(ms)')
box off
xlim([-500 949.75])
ylim([-20 20])
xticks([-900,-500,0,500,900])
set(gca,'fontsize',24,'FontName','Source Sans Variable')

saveas(gcf,['figures/responseFigures/clusterMean' num2str(cluster) '.svg'])

end



%% Show anatomical locations of clusters

normSize = cohDACC();
normSize(normSize < 0) = min(normSize(normSize > 0));


significantElectrodes = VERA.tala.electrodes(idx,:);

figure('color','white','Position',[1000         243        1304        1095]);


surf = plot3DModel(gca,VERA.cortex);
surf.FaceColor = [100,126,146]/256;
alpha(0.02)
hold on


for cluster = 1:length(uniqueClust)
    Clusteridx = find(dataOfInterest == uniqueClust(cluster));
    curChanels = significantElectrodes(Clusteridx,:);
    curColor = colors(cluster,:)/256;

for ch = 1:length(curChanels)
plotBallsOnVolume(gca,curChanels(ch,:),curColor,2)
hold on
end

end

view([180 0] )
saveas(gcf,'figures/clusterFigs/clustersFront.png')

view([-93.0402,-1])
saveas(gcf,'figures/clusterFigs/clustersBrainSide.png')

view([-2,90])
saveas(gcf,'figures/clusterFigs/clustersBrainTop.png')

view([ -494.1925 60.3828] )
saveas(gcf,'figures/clusterFigs/clustersBrainDiag.png')
%%

for ch1 = 1:numChans
for ch2 = 1:numChans


distanceMatrix(ch1,ch2) = pdist2(VERA.tala.electrodes(ch1,:),VERA.tala.electrodes(ch2,:));

end
end

%%
% Your correlation and distance matrices
correlationMatrixACC = (nanmean(data.ACCCoherence.task,3).^2);
correlationMatrixPCC = (nanmean(data.PCCCoherence.task,3).^2);

correlationArrayACC = correlationMatrixACC(triu(true(size(correlationMatrixACC)), 1));
correlationArrayPCC = correlationMatrixPCC(triu(true(size(correlationMatrixPCC)), 1));
% Enter your correlation matrix here
distanceArray = distanceMatrix(triu(true(size(distanceMatrix)), 1));     % Enter your distance matrix here



% Create the scatter plot
figure;
scatter(correlationArrayACC, distanceArray,'MarkerFaceColor',ACCRGB(1,:),'MarkerEdgeColor','black','SizeData',20,'AlphaData',0.5);
hold on

xlabel('Coherence (R^2)');
ylabel('Electrode Distance (mm)');
grid on;
set(gca,'fontsize',18,'FontName','Source Sans Variable')
box off

figure;
scatter(correlationArrayPCC, distanceArray,'MarkerFaceColor',PCCRGB(1,:),'MarkerEdgeColor','black','SizeData',20,'AlphaData',0.5);
hold on

xlabel('Coherence (R^2)');
ylabel('Electrode Distance (mm)');
grid on;
set(gca,'fontsize',18,'FontName','Source Sans Variable')
box off