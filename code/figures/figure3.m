%% for  figure components of figure 2
clear
close all
addpath(genpath(cd))

%add PEABrain to handle 3dd modeling
addpath(genpath('/Volumes/Samsung_T5/PEABrain'));
%
pooledData = load('data/pooledData.mat');
load('data/compiledData.mat');
load('code/dependencies/templateBrain.mat');
load('code/dependencies/listHip.mat');
load('code/dependencies/listAmyg.mat');
load('code/dependencies/cingulateNames.mat');
load('data/pooledBrain.mat');

hipAmyg = [listAmyg,listHip];
regionSort = readtable('code/dependencies/regionCategories.xlsx');
saveDir = 'figures/main/figure3/dependencies/';
mkdir(saveDir);

% get logical array for significant responses
alpha = calculateAlphaThreshold(pooledData.pValue, 0.0001);
significant = (pooledData.pValue < alpha) & (pooledData.cohensD > 0);

stimulated = logical(pooledData.stimulatedChannels);

sigChannelsIDX = find(pooledData.pValue < alpha);
stimRegion = [pooledData.stimulatedRegion{sigChannelsIDX}]; 
temp = [pooledData.stimulatedRegion{:}];
%index groups for each subregion of the cingulate
idx.lACC = find(ismember(stimRegion,leftACC));
idx.rACC = find(ismember(stimRegion,rightACC));
idx.lMCC = find(ismember(stimRegion,leftMCC));
idx.rMCC = find(ismember(stimRegion,rightMCC));
idx.lPCC = find(ismember(stimRegion,leftPCC));
idx.rPCC = find(ismember(stimRegion,rightPCC));
acc = ismember(temp,leftACC) | ismember(temp,rightACC);
mcc = ismember(temp,leftMCC) | ismember(temp,rightMCC);
pcc = ismember(temp,leftPCC) | ismember(temp,rightPCC);

%initialize colors
aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');

%initialize names of cingulate cortex for downstream indexing
cingulateNamesSimple = {'G_and_S_cingul-Ant'
'G_and_S_cingul-Mid-Ant'
'G_and_S_cingul-Mid-Post'
'G_cingul-Post-dorsal'
'G_cingul-Post-ventral'};

%create logical arrays for the stimulation conditions
condition.AStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(1));
condition.MStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(2:3));
condition.PStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(4:5));


%create cingulate cortex data structure (same as figure 1)
cingulateRegions.regions = rmfield(cortOut.regions,'otherRegions');

%colors for the cingulate 3D model
regionColorsCC = [getColors('lush lilac');
    getColors('lago blue');
    getColors('celadon porcelain');
    getColors('celadon porcelain');
    getColors('lago blue');
    0.2,0.2,0.2;
    0.2,0.2,0.2];

brainFieldnames = fieldnames(templateBrain.regions);

%% --- Step 1: Plot the Original Scatter Plot ---
figure('Position',[620   144   382   823]);
hold on;

% --- ACC ---
idxA = significant & acc & ~stimulated;
yA_all = pooledData.electrodeCoordinates(2, idxA);
normA_all = normalizeToRange(pooledData.cohensD(idxA), 0, 1);
scatter(normA_all, yA_all, 36, aColor, 'filled', 'MarkerFaceAlpha', 0.1);

% --- MCC ---
idxM = significant & mcc & ~stimulated;
yM_all = pooledData.electrodeCoordinates(2, idxM);
normM_all = normalizeToRange(pooledData.cohensD(idxM), 0, 1);
scatter(normM_all, yM_all, 36, mColor, 'filled', 'MarkerFaceAlpha', 0.1);

% --- PCC ---
idxP = significant & pcc & ~stimulated;
yP_all = pooledData.electrodeCoordinates(2, idxP);
normP_all = normalizeToRange(pooledData.cohensD(idxP), 0, 1);
scatter(normP_all, yP_all, 36, pColor, 'filled', 'MarkerFaceAlpha', 0.1);

% --- Step 2: Bin the Data Along the Y Axis and Compute Mean Effect Sizes ---
% Determine the overall y range (anterior-posterior axis)
allY = pooledData.electrodeCoordinates(2, significant & ~stimulated);
yMin = min(allY);
yMax = max(allY);
nbins = 50;  % Adjust the number of bins if needed
edges = linspace(yMin, yMax, nbins+1);
binCenters = (edges(1:end-1) + edges(2:end))/2;

% Preallocate arrays for the binned means
meanA = nan(1, nbins);
meanM = nan(1, nbins);
meanP = nan(1, nbins);

% Bin the ACC data
for i = 1:nbins
    binLower = edges(i);
    binUpper = edges(i+1);
    inBin = yA_all >= binLower & yA_all < binUpper;
    if any(inBin)
        meanA(i) = mean(normA_all(inBin));
    end
end

% Bin the MCC data
for i = 1:nbins
    binLower = edges(i);
    binUpper = edges(i+1);
    inBin = yM_all >= binLower & yM_all < binUpper;
    if any(inBin)
        meanM(i) = mean(normM_all(inBin));
    end
end

% Bin the PCC data
for i = 1:nbins
    binLower = edges(i);
    binUpper = edges(i+1);
    inBin = yP_all >= binLower & yP_all < binUpper;
    if any(inBin)
        meanP(i) = mean(normP_all(inBin));
    end
end

% --- Step 3: Fit a Trend Line to the Binned Means ---

% For ACC
validA = ~isnan(meanA);
pA = polyfit(binCenters(validA), meanA(validA), 4);  
trendA = polyval(pA, binCenters);

% For MCC
validM = ~isnan(meanM);
pM = polyfit(binCenters(validM), meanM(validM), 4);  
trendM = polyval(pM, binCenters);

% For PCC
validP = ~isnan(meanP);
pP = polyfit(binCenters(validP), meanP(validP), 4);  
trendP = polyval(pP, binCenters);

% --- Step 4: Overlay the Trend Lines on the Scatter Plot ---
% Plot the regression (trend) lines. The x-axis is the normalized effect size and the
% y-axis is the electrode's y coordinate (bin center).
plot(trendA, binCenters, '-', 'Color', aColor, 'LineWidth', 2);
plot(trendM, binCenters, '-', 'Color', mColor, 'LineWidth', 2);
plot(trendP, binCenters, '-', 'Color', pColor, 'LineWidth', 2);

% --- Step 5: calculate centroids of each line and plot
centerA = sum(binCenters .* trendA) / sum(trendA);
effectA = interp1(binCenters, trendA, centerA, "linear");
plot( effectA,centerA, 'o', 'MarkerSize',10,'MarkerFaceColor',aColor, 'MarkerEdgeColor', 'k')

centerM = sum(binCenters .* trendM) / sum(trendM);
effectM = interp1(binCenters, trendM, centerM, "linear");
plot( effectM,centerM, 'o','MarkerSize',10,'MarkerFaceColor',mColor, 'MarkerEdgeColor', 'k')

centerP = sum(binCenters .* trendP) / sum(trendP);
effectP = interp1(binCenters, trendP, centerP, "linear");
plot(effectP,centerP,  'o',  'MarkerSize', 10, 'MarkerFaceColor', pColor, 'MarkerEdgeColor', 'k') %effect is the x axis

% --- Final Figure Formatting ---
xlabel('Normalized Effect Size');
ylabel('Electrode Y Coordinate (Anterior-Posterior)');
set(gca, 'FontSize', 14);
box off;
hold off;
axis square

xlim([0,1])
saveas(gcf,[saveDir 'anteriorPosterior.svg'])
saveas(gcf,[saveDir 'anteriorPosterior.png'])

%% calculate Moran's I for each of the 3 stimulation categories
W = createWeightMatrix(binCenters);
[aI, aPValue] = moransI(trendA, W, 1000, 1);
saveas(gcf,[saveDir ['anteriorPosteriorMoransIDistacc.svg' ]])
[mI, mPValue] = moransI(trendM,W,1000,1);
saveas(gcf,[saveDir ['anteriorPosteriorMoransIDistmcc.svg' ]])
[pI,pPValue] = moransI(trendP,W,1000,1);
saveas(gcf,[saveDir ['anteriorPosteriorMoransIDistpcc.svg' ]])
%compare centroids of distributions
%acc to mcc
datIn = [trendA,trendM];
posIn = [binCenters,binCenters];
datLabels = [repmat(1,[1,length(trendA)]),repmat(2,[1,length(trendM)])];
[centerA, centerM, amPValue] = compareSpatialCentroids(posIn, datIn, datLabels, 1000, 1);
saveas(gcf,[saveDir ['anteriorPosteriorCentroidDistributionAM.svg' ]])


%acc to mcc
datIn = [trendA,trendP];
posIn = [binCenters,binCenters];
datLabels = [repmat(1,[1,length(trendA)]),repmat(2,[1,length(trendP)])];
[centerA, centerP, apPValue] = compareSpatialCentroids(posIn, datIn, datLabels, 1000, 1);
saveas(gcf,[saveDir ['anteriorPosteriorCentroidDistributionAP.svg' ]])

%pcc to mcc
datIn = [trendM,trendP];
posIn = [binCenters,binCenters];
datLabels = [repmat(1,[1,length(trendM)]),repmat(2,[1,length(trendP)])];
[centerM, centerP, mpPValue] = compareSpatialCentroids(posIn, datIn, datLabels, 1000, 1);
saveas(gcf,[saveDir ['anteriorPosteriorCentroidDistributionMP.svg' ]])

disp(['anterior-posterior am=' num2str(amPValue) ' ap=' num2str(apPValue) ' mp=' num2str(mpPValue)])


%% now repeat with z-axis

%% --- Step 1: Plot the Original Scatter Plot Using the Z-Axis ---
figure('Position',[620   144   382   823]);
hold on;

% --- ACC ---
idxA = significant & acc & ~stimulated;
zA_all = pooledData.electrodeCoordinates(3, idxA);  % Use Z-axis instead of Y
normA_all = normalizeToRange(pooledData.cohensD(idxA), 0, 1);
scatter(normA_all, zA_all, 36, aColor, 'filled', 'MarkerFaceAlpha', 0.1);

% --- MCC ---
idxM = significant & mcc & ~stimulated;
zM_all = pooledData.electrodeCoordinates(3, idxM);
normM_all = normalizeToRange(pooledData.cohensD(idxM), 0, 1);
scatter(normM_all, zM_all, 36, mColor, 'filled', 'MarkerFaceAlpha', 0.1);

% --- PCC ---
idxP = significant & pcc & ~stimulated;
zP_all = pooledData.electrodeCoordinates(3, idxP);
normP_all = normalizeToRange(pooledData.cohensD(idxP), 0, 1);
scatter(normP_all, zP_all, 36, pColor, 'filled', 'MarkerFaceAlpha', 0.1);

% --- Step 2: Bin the Data Along the Z-Axis and Compute Mean Effect Sizes ---
% Determine the overall z range
allZ = pooledData.electrodeCoordinates(3, significant & ~stimulated);
zMin = min(allZ);
zMax = max(allZ);
nbins = 50;  % Adjust this to change binning resolution
edges = linspace(zMin, zMax, nbins+1);
binCenters = (edges(1:end-1) + edges(2:end))/2;

% Preallocate arrays for the binned means
meanA = nan(1, nbins);
meanM = nan(1, nbins);
meanP = nan(1, nbins);

% Bin the ACC data
for i = 1:nbins
    binLower = edges(i);
    binUpper = edges(i+1);
    inBin = zA_all >= binLower & zA_all < binUpper;
    if any(inBin)
        meanA(i) = mean(normA_all(inBin));
    end
end

% Bin the MCC data
for i = 1:nbins
    binLower = edges(i);
    binUpper = edges(i+1);
    inBin = zM_all >= binLower & zM_all < binUpper;
    if any(inBin)
        meanM(i) = mean(normM_all(inBin));
    end
end

% Bin the PCC data
for i = 1:nbins
    binLower = edges(i);
    binUpper = edges(i+1);
    inBin = zP_all >= binLower & zP_all < binUpper;
    if any(inBin)
        meanP(i) = mean(normP_all(inBin));
    end
end

% --- Step 3: Fit a Trend Line to the Binned Means ---
% Fit a linear regression to the z-binned means

% For ACC
validA = ~isnan(meanA);
pA = polyfit(binCenters(validA), meanA(validA), 4);  
trendA = polyval(pA, binCenters);

% For MCC
validM = ~isnan(meanM);
pM = polyfit(binCenters(validM), meanM(validM), 4);  
trendM = polyval(pM, binCenters);

% For PCC
validP = ~isnan(meanP);
pP = polyfit(binCenters(validP), meanP(validP), 4);  
trendP = polyval(pP, binCenters);

% --- Step 4: Overlay the Trend Lines on the Scatter Plot ---
plot(trendA, binCenters, '-', 'Color', aColor, 'LineWidth', 2);
plot(trendM, binCenters, '-', 'Color', mColor, 'LineWidth', 2);
plot(trendP, binCenters, '-', 'Color', pColor, 'LineWidth', 2);

% --- Step 5: calculate centroids of each line and plot
centerA = sum(binCenters .* trendA) / sum(trendA);
effectA = interp1(binCenters, trendA, centerA, "linear");
plot( effectA,centerA, 'o', 'MarkerSize',10,'MarkerFaceColor',aColor, 'MarkerEdgeColor', 'k')

centerM = sum(binCenters .* trendM) / sum(trendM);
effectM = interp1(binCenters, trendM, centerM, "linear");
plot( effectM,centerM, 'o','MarkerSize',10,'MarkerFaceColor',mColor, 'MarkerEdgeColor', 'k')

centerP = sum(binCenters .* trendP) / sum(trendP);
effectP = interp1(binCenters, trendP, centerP, "linear");
plot(effectP,centerP,  'o',  'MarkerSize', 10, 'MarkerFaceColor', pColor, 'MarkerEdgeColor', 'k') %effect is the x axis


% --- Final Figure Formatting ---
xlabel('Normalized Effect Size');
ylabel('Electrode Z Coordinate (Superior - Inferior)');
set(gca, 'FontSize', 14);
box off;
% Uncomment to reverse the z-axis if needed
% set(gca, 'YDir', 'reverse');
hold off;
xlim([0,1])
axis square

saveas(gcf,[saveDir 'superiorInferior.svg'])
saveas(gcf,[saveDir 'superiorInferior.png'])

%% calculate Moran's I for each of the 3 stimulation categories
W = createWeightMatrix(binCenters);
[aI, aPValue] = moransI(trendA, W, 1000, 1);
saveas(gcf,[saveDir ['superiorInferiorMoransIDistacc.svg' ]])
[mI, mPValue] = moransI(trendM,W,1000,1);
saveas(gcf,[saveDir ['superiorInferiorMoransIDistmcc.svg' ]])
[pI,pPValue] = moransI(trendP,W,1000,1);
saveas(gcf,[saveDir ['superiorInferiorMoransIDistpcc.svg' ]])
%compare centroids of distributions
%acc to mcc
datIn = [trendA,trendM];
posIn = [binCenters,binCenters];
datLabels = [repmat(1,[1,length(trendA)]),repmat(2,[1,length(trendM)])];
[centerA, centerM, amPValue] = compareSpatialCentroids(posIn, datIn, datLabels, 1000, 1);
saveas(gcf,[saveDir ['superiorInferiorCentroidDistributionAM.svg' ]])


%acc to mcc
datIn = [trendA,trendP];
posIn = [binCenters,binCenters];
datLabels = [repmat(1,[1,length(trendA)]),repmat(2,[1,length(trendP)])];
[centerA, centerP, apPValue] = compareSpatialCentroids(posIn, datIn, datLabels, 1000, 1);
saveas(gcf,[saveDir ['superiorInferiorCentroidDistributionAP.svg' ]])

%pcc to mcc
datIn = [trendM,trendP];
posIn = [binCenters,binCenters];
datLabels = [repmat(1,[1,length(trendM)]),repmat(2,[1,length(trendP)])];
[centerM, centerP, mpPValue] = compareSpatialCentroids(posIn, datIn, datLabels, 1000, 1);
saveas(gcf,[saveDir ['superiorInferiorCentroidDistributionMP.svg' ]])

disp(['superior-inferior am=' num2str(amPValue) ' ap=' num2str(apPValue) ' mp=' num2str(mpPValue)])
%% now repeat with x axis

%% --- Step 1: Plot the Original Scatter Plot Using the X-Axis ---
figure('Position',[620   144   382   823]);
hold on;

% --- ACC ---
idxA = significant & acc & ~stimulated;
xA_all = pooledData.electrodeCoordinates(1, idxA);  % Use X-axis instead of Y or Z
normA_all = normalizeToRange(pooledData.cohensD(idxA), 0, 1);
scatter(normA_all, xA_all, 36, aColor, 'filled', 'MarkerFaceAlpha', 0.1);

% --- MCC ---
idxM = significant & mcc & ~stimulated;
xM_all = pooledData.electrodeCoordinates(1, idxM);
normM_all = normalizeToRange(pooledData.cohensD(idxM), 0, 1);
scatter(normM_all, xM_all, 36, mColor, 'filled', 'MarkerFaceAlpha', 0.1);

% --- PCC ---
idxP = significant & pcc & ~stimulated;
xP_all = pooledData.electrodeCoordinates(1, idxP);
normP_all = normalizeToRange(pooledData.cohensD(idxP), 0, 1);
scatter(normP_all, xP_all, 36, pColor, 'filled', 'MarkerFaceAlpha', 0.1);

% --- Step 2: Bin the Data Along the X-Axis and Compute Mean Effect Sizes ---
% Determine the overall x range (medial-lateral)
allX = pooledData.electrodeCoordinates(1, significant & ~stimulated);
xMin = min(allX);
xMax = max(allX);
nbins = 50;  % Adjust this to change binning resolution
edges = linspace(xMin, xMax, nbins+1);
binCenters = (edges(1:end-1) + edges(2:end))/2;

% Preallocate arrays for the binned means
meanA = nan(1, nbins);
meanM = nan(1, nbins);
meanP = nan(1, nbins);

% Bin the ACC data
for i = 1:nbins
    binLower = edges(i);
    binUpper = edges(i+1);
    inBin = xA_all >= binLower & xA_all < binUpper;
    if any(inBin)
        meanA(i) = mean(normA_all(inBin));
    end
end

% Bin the MCC data
for i = 1:nbins
    binLower = edges(i);
    binUpper = edges(i+1);
    inBin = xM_all >= binLower & xM_all < binUpper;
    if any(inBin)
        meanM(i) = mean(normM_all(inBin));
    end
end

% Bin the PCC data
for i = 1:nbins
    binLower = edges(i);
    binUpper = edges(i+1);
    inBin = xP_all >= binLower & xP_all < binUpper;
    if any(inBin)
        meanP(i) = mean(normP_all(inBin));
    end
end

% --- Step 3: Fit a Trend Line to the Binned Means ---
% Fit a linear regression to the x-binned means

% For ACC
validA = ~isnan(meanA);
pA = polyfit(binCenters(validA), meanA(validA), 4);  
trendA = polyval(pA, binCenters);

% For MCC
validM = ~isnan(meanM);
pM = polyfit(binCenters(validM), meanM(validM), 4);  
trendM = polyval(pM, binCenters);

% For PCC
validP = ~isnan(meanP);
pP = polyfit(binCenters(validP), meanP(validP), 4);  
trendP = polyval(pP, binCenters);

% --- Step 4: Overlay the Trend Lines on the Scatter Plot ---
plot(trendA, binCenters, '-', 'Color', aColor, 'LineWidth', 2);
plot(trendM, binCenters, '-', 'Color', mColor, 'LineWidth', 2);
plot(trendP, binCenters, '-', 'Color', pColor, 'LineWidth', 2);

% --- Step 5: calculate centroids of each line and plot
centerA = sum(binCenters .* trendA) / sum(trendA);
effectA = interp1(binCenters, trendA, centerA, "linear");
plot( effectA,centerA, 'o', 'MarkerSize',10,'MarkerFaceColor',aColor, 'MarkerEdgeColor', 'k')

centerM = sum(binCenters .* trendM) / sum(trendM);
effectM = interp1(binCenters, trendM, centerM, "linear");
plot( effectM,centerM, 'o','MarkerSize',10,'MarkerFaceColor',mColor, 'MarkerEdgeColor', 'k')

centerP = sum(binCenters .* trendP) / sum(trendP);
effectP = interp1(binCenters, trendP, centerP, "linear");
plot(effectP,centerP,  'o',  'MarkerSize', 10, 'MarkerFaceColor', pColor, 'MarkerEdgeColor', 'k') %effect is the x axis

% --- Final Figure Formatting ---
xlabel('Normalized Effect Size');
ylabel('Electrode X Coordinate (Lateral)');
set(gca, 'FontSize', 14);
box off;
% Uncomment to reverse the x-axis if needed
% set(gca, 'YDir', 'reverse');
hold off;
axis square

saveas(gcf,[saveDir 'leftRight.svg'])
saveas(gcf,[saveDir 'leftRight.png'])

%% calculate Moran's I for each of the 3 stimulation categories
W = createWeightMatrix(binCenters);
[aI, aPValue] = moransI(trendA, W, 1000, 1);
saveas(gcf,[saveDir ['leftRightMoransIDistacc.svg' ]])
[mI, mPValue] = moransI(trendM,W,1000,1);
saveas(gcf,[saveDir ['leftRightMoransIDistmcc.svg' ]])
[pI,pPValue] = moransI(trendP,W,1000,1);
saveas(gcf,[saveDir ['leftRightInferiorMoransIDistpcc.svg' ]])
%compare centroids of distributions
%acc to mcc
datIn = [trendA,trendM];
posIn = [binCenters,binCenters];
datLabels = [repmat(1,[1,length(trendA)]),repmat(2,[1,length(trendM)])];
[centerA, centerM, amPValue] = compareSpatialCentroids(posIn, datIn, datLabels, 1000, 1);
saveas(gcf,[saveDir ['leftRightCentroidDistributionAM.svg' ]])

%acc to mcc
datIn = [trendA,trendP];
posIn = [binCenters,binCenters];
datLabels = [repmat(1,[1,length(trendA)]),repmat(2,[1,length(trendP)])];
[centerA, centerP, apPValue] = compareSpatialCentroids(posIn, datIn, datLabels, 1000, 1);
saveas(gcf,[saveDir ['leftRightCentroidDistributionAP.svg' ]])

%pcc to mcc
datIn = [trendM,trendP];
posIn = [binCenters,binCenters];
datLabels = [repmat(1,[1,length(trendM)]),repmat(2,[1,length(trendP)])];
[centerM, centerP, mpPValue] = compareSpatialCentroids(posIn, datIn, datLabels, 1000, 1);
saveas(gcf,[saveDir ['leftRightCentroidDistributionMP.svg' ]])

disp(['left-right am=' num2str(amPValue) ' ap=' num2str(apPValue) ' mp=' num2str(mpPValue)])

%% create histograms of each coordinate

%% --- Step 1: Extract Coordinate Data by Condition ---
% X-axis (Medial-Lateral)
xA = pooledData.electrodeCoordinates(1,  acc & ~stimulated);
xM = pooledData.electrodeCoordinates(1, mcc & ~stimulated);
xP = pooledData.electrodeCoordinates(1,  pcc & ~stimulated);
%significant Only
xAs = pooledData.electrodeCoordinates(1,  significant & acc & ~stimulated);
xMs = pooledData.electrodeCoordinates(1, significant & mcc & ~stimulated);
xPs = pooledData.electrodeCoordinates(1,  significant & pcc & ~stimulated);

% SigTest of normalized probabilities
resultsX = compareBinProportions(xA, xM, xP,50,xAs,xMs,xPs);


% Y-axis (Anterior-Posterior)
yA = pooledData.electrodeCoordinates(2, acc & ~stimulated);
yM = pooledData.electrodeCoordinates(2,  mcc & ~stimulated);
yP = pooledData.electrodeCoordinates(2,  pcc & ~stimulated);
%significant only
yAs = pooledData.electrodeCoordinates(2, significant & acc & ~stimulated);
yMs = pooledData.electrodeCoordinates(2,  significant & mcc & ~stimulated);
yPs = pooledData.electrodeCoordinates(2,  significant & pcc & ~stimulated);

% SigTest
resultsY = compareBinProportions(yA, yM, yP,50,yAs,yMs,yPs);

% Z-axis (Depth)
zA = pooledData.electrodeCoordinates(3,  acc & ~stimulated);
zM = pooledData.electrodeCoordinates(3,  mcc & ~stimulated);
zP = pooledData.electrodeCoordinates(3,  pcc & ~stimulated);
%
zAs = pooledData.electrodeCoordinates(3, significant & acc & ~stimulated);
zMs = pooledData.electrodeCoordinates(3, significant & mcc & ~stimulated);
zPs = pooledData.electrodeCoordinates(3, significant & pcc & ~stimulated);

% SigTest
resultsZ = compareBinProportions(zA, zM, zP, 50,zAs,zMs,zPs);

% Define number of bins (adjustable)
nbins = 50;
% --- Step 2: Plot Histogram for X-Coordinates ---
figure;
hold on;
histogram(xA, 'BinEdges', resultsX.binEdges, 'Normalization', 'probability', 'FaceColor', aColor, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
histogram(xM, 'BinEdges', resultsX.binEdges,'Normalization', 'probability',  'FaceColor', mColor, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
histogram(xP, 'BinEdges', resultsX.binEdges,'Normalization', 'probability',  'FaceColor', pColor, 'FaceAlpha', 0.25, 'EdgeColor', 'none');

for i = 1:length(resultsX.binCenters) 
%check if current bin is significantly different
check = [resultsX.p12(i),resultsX.p13(i),resultsX.p23(i)] < 0.05/length(resultsX.binCenters);
if any(check)
plot([resultsX.binCenters(i), resultsX.binCenters(i)], [0, .01], 'LineWidth',.75,'Color', 'r')
end
end
xlabel('X Coordinate (Medial-Lateral)');
ylabel('Count');
title('Histogram of Electrode X Coordinates by Condition');
set(gca, 'FontSize', 14);
box off;
xlim([-80 80])
set(gca, 'Xdir', 'reverse','linewidth',.75)
hold off;

saveas(gcf,[saveDir 'leftRightCoverage.svg'])
saveas(gcf,[saveDir 'leftRightCoverage.png'])

% --- Step 3: Plot Histogram for Y-Coordinates ---
figure;
hold on;
histogram(yA, 'BinEdges', resultsY.binEdges,'Normalization', 'probability',  'FaceColor', aColor, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
histogram(yM, 'BinEdges', resultsY.binEdges,'Normalization', 'probability',  'FaceColor', mColor, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
histogram(yP, 'BinEdges', resultsY.binEdges,'Normalization', 'probability',  'FaceColor', pColor, 'FaceAlpha', 0.25, 'EdgeColor', 'none');

for i = 1:length(resultsY.binCenters) 
%check if current bin is significantly different
check = [resultsY.p12(i),resultsY.p13(i),resultsY.p23(i)] < 0.05/length(resultsY.binCenters);
if any(check)
plot([resultsY.binCenters(i), resultsY.binCenters(i)], [0, .01], 'LineWidth',.75,'Color', 'r')
end
end

xlabel('Y Coordinate (Anterior-Posterior)');
ylabel('Count');
title('Histogram of Electrode Y Coordinates by Condition');
set(gca, 'FontSize', 14);
box off;
xlim([-60 80])
set(gca, 'Xdir', 'reverse','linewidth',.75)
hold off;

saveas(gcf,[saveDir 'anteriorPosteriorCoverage.svg'])
saveas(gcf,[saveDir 'anteriorPosteriorCoverage.png'])

% --- Step 4: Plot Histogram for Z-Coordinates ---
figure;
hold on;
histogram(zA, 'BinEdges', resultsZ.binEdges,'Normalization', 'probability',  'FaceColor', aColor, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
histogram(zM, 'BinEdges', resultsZ.binEdges, 'Normalization', 'probability', 'FaceColor', mColor, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
histogram(zP, 'BinEdges', resultsZ.binEdges, 'Normalization', 'probability', 'FaceColor', pColor, 'FaceAlpha', 0.25, 'EdgeColor', 'none');

for i = 1:length(resultsZ.binCenters) 
%check if current bin is significantly different
check = [resultsZ.p12(i),resultsZ.p13(i),resultsZ.p23(i)] < 0.05/length(resultsZ.binCenters);
if any(check)
plot([resultsZ.binCenters(i), resultsZ.binCenters(i)], [0, .01], 'LineWidth',.75,'Color', 'r')
end
end

xlabel('Z Coordinate (Depth)');
ylabel('Count');
title('Histogram of Electrode Z Coordinates by Condition');
set(gca, 'FontSize', 14);
box off;
xlim([-60 80])
set(gca, 'Xdir', 'reverse','linewidth',.75)
hold off;
saveas(gcf,[saveDir 'superiorInferiorCoverage.svg'])
saveas(gcf,[saveDir 'superiorInferiorCoverage.png'])

%% Figure 3 B. Connection lateralization- create a wiring diagram showing the laterality of each connection
%for each reigon, check to see if coverage exists on both sides, then
%color each line on the wiring diagram based on the difference left-right,
%where 1 color represents dominance on one side and another color
%represents dominance for the other. The center color should indicate no
%difference. 

%%
%% First, extract necessary data to feed into the figure generating engine, similar to the network figure in figure 2

%Reorganize table by merging somatosensory and motor regions, and remove
%any class regions "Other"
figureRegions = regionSort;
merge = contains(figureRegions.Class,{'Motor Cortex','Somatosensory Cortex'});
mergeTo = 'Somato-Motor Cortex';

remove = contains(figureRegions.Class,{'Occipital Lobe', 'Other', 'White Matter', 'White matter'});

figureRegions.Class(merge) = {mergeTo};
figureRegions(remove,:) = [];

%reorder and sort regions by region CLass
classOrder = {'Orbitofrontal cortex','Frontal Lobe','Cingulate cortex','Somato-Motor Cortex','Operculum','Temporal Lobe','Hippocampus','Amygdala','Insula','Parietal Lobe','Occipital Lobe','Thalamus'};

[~,idx] = ismember(figureRegions.Class,classOrder);
[~,sortIDX] = sort(idx);
figureRegions = figureRegions(sortIDX,:);
figureRegions = removevars(figureRegions,'Region');

[~,groupLabels] = ismember(figureRegions.Class,classOrder);

% Using the y coordinates of electrodes with labels, organize the table
% region names within each group to be from anterior to posterior
groupLabelsUnique = unique(groupLabels);

% iterate through each group, identify all the regions, obtain an average y
% value for each, reorder based on anterior to posterior of each group
for g = 1:length(groupLabelsUnique)
initDistances = [];

curRegionsIDX = groupLabels == groupLabelsUnique(g);
curRegions = figureRegions.Name(curRegionsIDX);

%initialize and store temporary average position of electrodes regions within the class label, 

tempDistances = [];

for r = 1:length(curRegions)
regionsIDX = contains([pooledData.electrodeRegionLabel{:}],curRegions{r});
tempDistances(r) = mean(pooledData.electrodeCoordinates(2,regionsIDX));
end

%oranize and resort by rank, then amend table as needed 
[~,idx] = sort(tempDistances,'descend');
curRegions = curRegions(idx);
figureRegions.Name(curRegionsIDX) = curRegions;
end

%% remove any table entries where the region does not exist in the dataset.
close all
regions = unique([pooledData.electrodeRegionLabel{:}]);

%since data labels contain more characters than table labels, we will have
%to loop through and use the contains function for each individual element.
%Also, do not include the cingul-Marginalis as part of this divergent
%connectivity figure since it is not one of the regions of interest.
count = 1;
temp = [];
for i = 1:length(figureRegions.Name)
    if ~any(contains(regions,figureRegions.Name(i))) || strcmp(figureRegions.Name(i), 'S_cingul-Marginalis')
        temp(count) = i;
        count = count+1;
    end
end

figureRegions(temp,:) = [];

% here, generate a set of tables that contain the information required for generating inner and outter circles
%figureRegions contains the necessary region names and region classes, the
%function that generates the circles will double all of the labels 
outerTable = figureRegions(~ismember(figureRegions.Name,cingulateNamesSimple),:);
innerTable = figureRegions(contains(figureRegions.Name,cingulateNamesSimple),:);

%change class labels for innerTable for stimulation conditions
innerTable.Class = {'ACC';'MCC';'MCC';'PCC';'PCC'};

%% create wiring figure
%generate necessary geometric resources to create the wiring figure
[outer, inner] = generateCircleNetworkPoints(15,3, 4, 12, outerTable, innerTable); %use a full circle diagram, then prune it to a half circle in the next few lines to ensure that indexing is consistent)

%%
removeIDXOuter = outer.rHemisphere == 0;
removeIDXInner = inner.rHemisphere == 0;
outer(removeIDXOuter,:) = [];
inner(removeIDXInner,:) = [];
inner = flip(inner);

%
[a,b,c] = generateNetworkPlotHalfCircle(outer, inner, pooledData, 'cohensD', significant,'ipsi','jitter','jitterMagnitude',.02); %'offset',  'offsetStep', 0.005);
saveas(a,[saveDir 'ipsiLateralizationPlot.svg'])
saveas(b,[saveDir 'ipsiLateralizationPlotLegendBlue.svg'])
saveas(c,[saveDir 'ipsiLateralizationPlotLegendRed.svg'])

%
[a,b,c] = generateNetworkPlotHalfCircle(outer, inner, pooledData, 'cohensD', significant,'contra','jitter','jitterMagnitude',.02); %'offset',  'offsetStep', 0.005);
saveas(a,[saveDir 'contraLateralizationPlot.svg'])
saveas(b,[saveDir 'contraLateralizationPlotLegendBlue.svg'])
saveas(c,[saveDir 'contraLateralizationPlotLegendRed.svg'])

%% generate statistical comparisons between major region groups, based on the figureRegions classes

lateralizationTableCohD = getHemiStats(outer, inner,pooledData, 'cohensD', significant);

%repeat for RMS regions
alphaRMS = calculateAlphaThreshold(pooledData.RMSP, 0.0001);
significantRMS = (pooledData.RMSP < alpha) & (pooledData.RMS > 0);

%%
lateralizationTableRMS = getHemiStats(outer, inner,pooledData, 'RMS', significantRMS);

[a,b,c] = generateNetworkPlotHalfCircle(outer, inner, pooledData, 'RMS', significantRMS,'ipsi','jitter','jitterMagnitude',.02); %'offset',  'offsetStep', 0.005);
saveas(a,[saveDir 'ipsiLateralizationPlotRMS.svg'])
saveas(b,[saveDir 'ipsiLateralizationPlotLegendBlueRMS.svg'])
saveas(c,[saveDir 'ipsiLateralizationPlotLegendRedRMS.svg'])

%
[a,b,c] = generateNetworkPlotHalfCircle(outer, inner, pooledData, 'RMS', significantRMS,'contra','jitter','jitterMagnitude',.02); %'offset',  'offsetStep', 0.005);
saveas(a,[saveDir 'contraLateralizationPlotRMS.svg'])
saveas(b,[saveDir 'contraLateralizationPlotLegendBlueRMS.svg'])
saveas(c,[saveDir 'contraLateralizationPlotLegendRedRMS.svg'])

%% Generate Sup. Figure of brain maps for all conditions and for RMS

%% Now repeat for supplemental brain maps -> these will require 3 colors and an alpha value

%conditions
effectSizes = [];
effectVariation = [];
numSubjects = [];
includedRegion = logical([]);
percentSignificant = [];

LHem = pooledData.electrodeCoordinates(1,:) < 0;
RHem = pooledData.electrodeCoordinates(1,:) > 0;

%% create anatomical figures for differences in contralateral connectivity
LStim = contains([pooledData.stimulatedRegion{:}],'_lh_');
RStim = contains([pooledData.stimulatedRegion{:}],'_rh_');

for i = 1:length(templateBrain.regionList)
    %find all channels within the brain region
    curRegion = contains([pooledData.electrodeRegionLabel{:}],templateBrain.regionList{i});
    
    if sum(curRegion) == 0
        storeZeros(i) = 1;

    else
        storeZeros(i) = 0;
    end
    %generate logical arrays for each condition, meeting significance,
    %within current region

    tempACCL = LStim & condition.AStim & curRegion & significant & ~stimulated & LHem;
    tempACCR = RStim & condition.AStim & curRegion & significant & ~stimulated & RHem;

    tempMCCL = LStim & condition.MStim & curRegion & significant & ~stimulated & LHem;
    tempMCCR = RStim & condition.MStim & curRegion & significant & ~stimulated & RHem;
    
    tempPCCL = LStim & condition.PStim & curRegion & significant & ~stimulated & LHem;
    tempPCCR = RStim & condition.PStim & curRegion & significant & ~stimulated & RHem;
    
    if (sum(tempACCL) == 0) || (sum(tempACCR) == 0)
        effectSizes(i,:) = nan;
    else
        effectSizes(i,1) = nanmean(pooledData.cohensD(tempACCR)) - nanmean(pooledData.cohensD(tempACCL));
    end

    if (sum(tempMCCL) == 0) || (sum(tempMCCR) == 0)
        effectSizes(i,2) = nan;
    else
        effectSizes(i,2) = nanmean(pooledData.cohensD(tempMCCR)) - nanmean(pooledData.cohensD(tempMCCL));
    end

    if (sum(tempPCCL) == 0) || (sum(tempPCCR) == 0)
        effectSizes(i,3) = nan;
    else
        effectSizes(i,3) = nanmean(pooledData.cohensD(tempPCCR)) - nanmean(pooledData.cohensD(tempPCCL));
    end

        if any(contains(cingulateNamesSimple(1),templateBrain.regionList{i}))
        effectSizes(i,1) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif any(contains(cingulateNamesSimple(2:3),templateBrain.regionList{i}))
        effectSizes(i,2) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif any(contains(cingulateNamesSimple(4:5),templateBrain.regionList{i}))
        effectSizes(i,3) = nan;% set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        end

        storeNoCoverage(i,:) = [0,0,0];

        if sum(condition.AStim & curRegion & ~stimulated) == 0
        storeNoCoverage(i,1) = 1;
        end
        if sum(condition.MStim & curRegion & ~stimulated) == 0
        storeNoCoverage(i,2) = 1;
        end
        if sum(condition.PStim & curRegion & ~stimulated) == 0
        storeNoCoverage(i,3) = 1;
        end
end

%% initialize brain structures
% generate brain without a hippocampus
hipAmygBool = contains(templateBrain.regionList,hipAmyg);%hip/amyg fieldnames already exist in a separate .mat file
brainFieldnames2 = brainFieldnames(~hipAmygBool);

for i = 1:length(brainFieldnames2)

    templateBrain2.regions.(brainFieldnames2{i}) = templateBrain.regions.(brainFieldnames2{i});

end

%for using a right brain model, show the midsection and remove regions from
%sagittal view
templateBrainRight = getOneSide(templateBrain2,'right');
templateBrainRight = isolatePortionOfModel(templateBrainRight,'x','less',27);

templateBrainLeft = getOneSide(templateBrain,'left');
templateBrainLeft = isolatePortionOfModel(templateBrainLeft,'x','less',-15);

% generate model of the hippocampus 
hipAmygBool = contains(templateBrain.regionList,hipAmyg);%hip/amyg fieldnames already exist in a separate .mat file
hipAmygFieldnames = brainFieldnames(hipAmygBool);

%make new struct for hipp and amyg
for i = 1:length(hipAmygFieldnames)

    hipAmygTemplate.regions.(hipAmygFieldnames{i}) = templateBrain.regions.(hipAmygFieldnames{i});

end
hipAmygTemplate = getOneSide(hipAmygTemplate,'left');

insulaBool = contains(templateBrain.regionList,regionSort{strcmp(regionSort{:,3},'Insula'),1}); %extract insula fieldnames from table
insulaFieldnames = brainFieldnames(insulaBool); %ensure that fieldnames are ordered accordingly 
%index insula subregions and generate an insula struct
for i = 1:length(insulaFieldnames)
   insulaTemplate.regions.(insulaFieldnames{i}) = templateBrain.regions.(insulaFieldnames{i});
end
insulaTemplateLeft = getOneSide(insulaTemplate,'left');



%% Make figures for ipsilateral stimulation 
%normalize each row so that maximum alpha can be assigned as between 0.2 and .7
aAlphas = effectSizes(:,1);
aNan = isnan(aAlphas); %store nan values to adjust to grey
storeZeros = logical(storeZeros);
noCover = logical(storeNoCoverage(:,1));
blueIDX = effectSizes(:,1) <0;
redIDX = effectSizes(:,1) >0;

aColors = mapEffectSizesToColors(effectSizes(:,1), getColors('modern blue to muted brick gradient'));
aColors(aNan,:) = 0.8;
aColors(noCover,:) = 0.4;
aColors(storeZeros,:) = 0.4;


%First Plot everything for ACC
figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainLeft,aColors);

view([270,0])

saveas(gcf,[saveDir 'connectivityACCCortexIpsi1.svg'])
saveas(gcf,[saveDir 'connectivityACCCortexIpsi1.png'])

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainRight,aColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityACCCortexIpsi2.svg'])
saveas(gcf,[saveDir 'connectivityACCCortexIpsi2.png'])

figure('Position',[281          32        3060        1260]);
insulaColors = aColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulaColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityACCInsulaIpsi.svg'])
saveas(gcf,[saveDir 'connectivityACCInsulaIpsi.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = aColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])
saveas(gcf,[saveDir 'connectivityACCHipIpsi1.svg'])
saveas(gcf,[saveDir 'connectivityACCHipIpsi1.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = aColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])
saveas(gcf,[saveDir 'connectivityACCHipIpsi2.svg'])
saveas(gcf,[saveDir 'connectivityACCHipIpsi2.png'])

clim = max(abs(effectSizes(:,1)));
figure();
colormap(getColors('modern blue to muted brick gradient'))
caxis([-clim clim]);
colorbar
saveas(gcf,[saveDir 'connectivityACCLegend.svg'])

%%
mAlphas = effectSizes(:,2);
mNan = isnan(mAlphas); %store nan values to adjust to grey
noCover = logical(storeNoCoverage(:,2));
blueIDX = effectSizes(:,2) <0;
redIDX = effectSizes(:,2) >0;


mColors = mapEffectSizesToColors(effectSizes(:,2), getColors('modern blue to muted brick gradient'));

mColors(mNan,:) = 0.8;
mColors(noCover,:) = 0.4;
mColors(storeZeros,:) = 0.4;

%First Plot everything for ACC
figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainLeft,mColors);
view([270,0])

saveas(gcf,[saveDir 'connectivityMCCCortexIpsi1.svg'])
saveas(gcf,[saveDir 'connectivityMCCCortexIpsi1.png'])

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainRight,mColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityMCCCortexIpsi2.svg'])
saveas(gcf,[saveDir 'connectivityMCCCortexIpsi2.png'])

figure('Position',[281          32        3060        1260]);
insulaColors = mColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulaColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityMCCInsulaIpsi.svg'])
saveas(gcf,[saveDir 'connectivityMCCInsulaIpsi.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = mColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])
saveas(gcf,[saveDir 'connectivityMCCHipIpsi1.svg'])
saveas(gcf,[saveDir 'connectivityMCCHipIpsi1.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = mColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])
saveas(gcf,[saveDir 'connectivityMCCHipIpsi2.svg'])
saveas(gcf,[saveDir 'connectivityMCCHipIpsi2.png'])

clim = max(abs(effectSizes(:,2)));
figure();
colormap(getColors('modern blue to muted brick gradient'))
caxis([-clim clim]);
colorbar
saveas(gcf,[saveDir 'connectivityMCCLegend.svg'])

%%
pAlphas = effectSizes(:,3);
pNan = isnan(pAlphas); %store nan values to adjust to grey
noCover = logical(storeNoCoverage(:,3));
blueIDX = effectSizes(:,3) <0;
redIDX = effectSizes(:,3) >0;
pColors = mapEffectSizesToColors(effectSizes(:,3), getColors('modern blue to muted brick gradient'));
pColors(pNan,:) = 0.8;
pColors(noCover,:) = 0.4;
pColors(storeZeros,:) = 0.4;

%First Plot everything for ACC
figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainLeft,pColors);
view([270,0])

saveas(gcf,[saveDir 'connectivityPCCCortexIpsi1.svg'])
saveas(gcf,[saveDir 'connectivityPCCCortexIpsi1.png'])

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainRight,pColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityPCCCortexIpsi2.svg'])
saveas(gcf,[saveDir 'connectivityPCCCortexIpsi2.png'])

figure('Position',[281          32        3060        1260]);
insulaColors = pColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulaColors);
view([270,0])
saveas(gcf,[saveDir 'connectivityPCCInsulaIpsi.svg'])
saveas(gcf,[saveDir 'connectivityPCCInsulaIpsi.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = pColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])
saveas(gcf,[saveDir 'connectivityPCCHipIpsi1.svg'])
saveas(gcf,[saveDir 'connectivityPCCHipIpsi1.png'])

figure('Position',[281          32        3060        1260]);
hipAmygColors = pColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])
saveas(gcf,[saveDir 'connectivityPCCHipIpsi2.svg'])
saveas(gcf,[saveDir 'connectivityPCCHipIpsi2.png'])

clim = max(abs(effectSizes(:,3)));
figure();
colormap(getColors('modern blue to muted brick gradient'))
caxis([-clim clim]);
colorbar
saveas(gcf,[saveDir 'connectivityPCCLegend.svg'])