%% for  figure components of figure 2
clear all
addpath(genpath(cd))
%
pooledData = load('data/pooledData.mat');
load('data/compiledData.mat');
load('code/dependencies/templateBrain.mat');
load('code/dependencies/listHip.mat');
load('code/dependencies/listAmyg.mat');

hipAmyg = [listAmyg,listHip];

regionSort = readtable('code/dependencies/regionCategories.xlsx');
saveDir = 'figures/main/figure2/dependencies';
mkdir(saveDir);

%% initialize variables
leftH = '_lh_';
rightH = '_rh_';

cingulateNamesSimple = {'G_and_S_cingul-Ant'
'G_and_S_cingul-Mid-Ant'
'G_and_S_cingul-Mid-Post'
'G_cingul-Post-dorsal'
'G_cingul-Post-ventral'};

% get logical array for significant responses
alpha = calculateAlphaThreshold(pooledData.pValue, 0.05);

significant = pooledData.pValue < alpha;

%create logical arrays for the stimulation conditions
condition.AStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(1));
condition.MStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(2:3));
condition.PStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(4:5));

brainFieldnames = fieldnames(templateBrain.regions);
%% color coding each region by relative and absolute connectivity-> for each region, store the color of the region

%using COhen's D, generate a set of colors and triangular coordinates that
%correspond to the geometric mean of each region given the 3 above
%conditions
colors = [];
coordinates = [];
numSubjects = [];
includedRegion = logical([]);

figure;
for i = 1:length(templateBrain.regionList)
    %find all channels within the brain region
    curRegion = contains([pooledData.electrodeRegionLabel{:}],templateBrain.regionList{i});

    %check number of subjects with coverage in this region
    numSubjects(i) = length(unique(pooledData.subjectID(curRegion)));

    %generate logical arrays for each condition, meeting significance,
    %within current region
    if ~any(curRegion)% check to see if any coverage exists (black if there is no color)
    colors(i,:) = [0.2,0.2,0.2];
    coordinates(i,:) = [nan,nan]; 
    includedRegion(i) = 0;
    else
    tempACC = condition.AStim & curRegion & significant;
    tempMCC = condition.MStim & curRegion & significant;
    tempPCC = condition.PStim & curRegion & significant;
    end


    % check to make sure at least one value exists for each of the three
    % above groups
    if all([any(tempACC),any(tempMCC),any(tempPCC)])
    % generate a triangular geometric mean to assign color
    a = nanmean(pooledData.cohensD(tempACC));
    m = nanmean(pooledData.cohensD(tempMCC));
    p = nanmean(pooledData.cohensD(tempPCC));

    values = [a,m,p];

    [colors(i,:),coordinates(i,:)] = triangularGeoMean(values,'off');
    includedRegion(i) = 1;
    else
    % assign white as the color
    colors(i,:) = [0.2,0.2,0.2];
    coordinates(i,:) = [nan,nan];
    includedRegion(i) = 0;
    end


end
colors(isnan(colors)) = 0.8;
%plot figure using colors
figure;
templateBrainRight = getOneSide(templateBrain,'right');
[surface] = plotProjectedRegionsOnly(templateBrainRight,colors);

%change faceAlplha for all non-included regions to 0.02
alphaIDX = find(includedRegion == 0);
for i = alphaIDX
surface(i).FaceColor = [0.8,0.8,0.8];
end

%% generate model of the hippocampus 
hipAmygBool = contains(templateBrain.regionList,hipAmyg);
hipAmygFieldnames = brainFieldnames(hipAmygBool);
hipAmygColors = colors(hipAmygBool,:);
includedHA = includedRegion(hipAmygBool);

%make new struct for hipp and amyg
for i = 1:length(hipAmygFieldnames)

    hipAmygTemplate.regions.(hipAmygFieldnames{i}) = templateBrainRight.regions.(hipAmygFieldnames{i});

end

figure;
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);

alphaIDXHA = find(includedHA == 0);
for i = alphaIDXHA
surfaceHA(i).FaceColor = [0.8,0.8,0.8];
surfaceHA(i).FaceAlpha = 0.5;
end

%%

Sig = pooledData.pValue < (0.05/length(pooledData.pValue));

aE = pooledData.electrodeCoordinates(:,(AStim & Sig))';
mE = pooledData.electrodeCoordinates(:,(MStim & Sig))';
pE = pooledData.electrodeCoordinates(:,(PStim & Sig))';

aRho = pooledData.cohensD((AStim & Sig));
mRho = pooledData.cohensD((MStim & Sig));
pRho = pooledData.cohensD((PStim & Sig));

[nA, rA, aC] = electrodeEffectSizes(aRho,getColors('lush lilac black gradient'),1.5,4);
[nM, rM, mC] = electrodeEffectSizes(mRho,getColors('celadon porcelain black gradient'),1.5,4);
[nP, rP, pC] = electrodeEffectSizes(pRho,getColors('lago blue black gradient'),1.5,4);

%%

regionColors2 = [[.8,0,0.1];
    [.8,0,0.1];
    [.8,0,0.1];
    [.8,0,0.1];
    [.8,0,0.1];
    0.2,0.2,0.2];

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(cortOut,regionColors2);
for i = 1:length(surface)
surface(i).FaceAlpha = 0.05;
end
surface(6).FaceAlpha = 0.03;

hold on

for ch = 1:length(rM)
curChan = mE(ch,:);
curColor = mC(ch,:);
curR = rM(ch);

plotBallsOnVolume(gca,curChan, curColor, curR);
end
