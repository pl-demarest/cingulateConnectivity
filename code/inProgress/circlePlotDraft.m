%%

% Load Pooled Data
clear all
%close all

clear
addpath(genpath(cd))
pooledData = load('data/pooledData.mat');
load("code/dependencies/cingulateID.mat") % anatomical IDs of cingulate cortex channels
labelTable = readtable("code/dependencies/labelTable.txt"); % table containing all relevant info for anatomical atlas
load("code/dependencies/SEEGClinical22ChanLoc_xyz.mat") % EEG Channel Info
load("code/dependencies/mniMRI.mat")
regionTable = readtable("code/dependencies/regionCategories.xlsx");
regionIDX = find(ismember(labelTable.Var1,cingulateID));
cingulateRegionNames = {labelTable.Var2{regionIDX}}';

cingulateNamesSimple = {'G_and_S_cingul-Ant'
'G_and_S_cingul-Mid-Ant'
'G_and_S_cingul-Mid-Post'
'G_cingul-Post-dorsal'
'G_cingul-Post-ventral'};

%What order should the regions be sorted by?
regionOrdered = {'Orbitofrontal cortex','Frontal Lobe','Motor Cortex','Somatosensory Cortex','Operculum','Temporal Lobe','Hippocampus','Amygdala','Insula','Parietal Lobe','Occipital Lobe','Thalamus','White matter','Other'};

% Different color for each class-> one for each hemisphere
colors =     [[162, 127, 184]./255;[68,200,149]./255;[34, 175, 194]./255]; 
colors = [colors; flip(colors)];
colormap = getColors('vivid greyscale');
colormap = colormap(1:length(regionOrdered),:);
%
rightACC = {'ctx_rh_G_and_S_cingul-Ant','wm_rh_G_and_S_cingul-Ant'};
leftACC = {'ctx_lh_G_and_S_cingul-Ant','wm_lh_G_and_S_cingul-Ant'};

rightMCC = {'ctx_rh_G_and_S_cingul-Mid-Ant','ctx_rh_G_and_S_cingul-Mid-Post','wm_rh_G_and_S_cingul-Mid-Ant','wm_rh_G_and_S_cingul-Mid-Post'};
leftMCC = {'ctx_lh_G_and_S_cingul-Mid-Ant','ctx_lh_G_and_S_cingul-Mid-Post','wm_lh_G_and_S_cingul-Mid-Ant','wm_lh_G_and_S_cingul-Mid-Post'};

rightPCC = {'ctx_rh_G_cingul-Post-dorsal', 'ctx_rh_G_cingul-Post-ventral', 'wm_rh_G_cingul-Post-dorsal','wm_rh_G_cingul-Post-ventral'};
leftPCC = {'ctx_lh_G_cingul-Post-dorsal','ctx_lh_G_cingul-Post-ventral','wm_lh_G_cingul-Post-dorsal','wm_lh_G_cingul-Post-ventral'};

groups = {leftACC;leftMCC;leftPCC;rightPCC;rightMCC;rightACC};

%% format data
%extract list of regions and classes
regions = regionTable.Name;
regionClasses = regionTable.Class;

% extract indexes of significant channels as per multiple correction
% method:
sigIDX = find(pooledData.pValue < alpha);
cohD = pooledData.cohensD(sigIDX);
var = pooledData.variance(sigIDX);
coords = pooledData.electrodeCoordinates(:,sigIDX);
eRegions = [pooledData.electrodeRegionLabel{sigIDX}];
stimedRegion = [pooledData.stimulatedRegion{sigIDX}];


%% separate cingulate cortex from other regions
nonCingulateRegionsIDX = find(contains(regions , cingulateNamesSimple)==1);
nonCingulateRegions = regions;
nonCingulateRegions(nonCingulateRegionsIDX) = [];
nonCingulateClasses = regionClasses;
nonCingulateClasses(nonCingulateRegionsIDX) = [];


%% generarte a circle  

[outer,intermediate1, intermediate2, inner] = generateCircleNetworkPoints(15,3,2*(length(regions)-length(nonCingulateRegionsIDX)),length(groups),outerLabels,12,8);

%% Plot the circle 
lastPointIDX = 1;


%initialize storage

%intitialize storage vectors for Outer Circle
storeCohDLeft = nan(length(groups),length(nonCingulateRegions));
storeCohDRight = nan(length(groups),length(nonCingulateRegions));

storeVarLeft = nan(length(groups),length(nonCingulateRegions));
storeVarRight = nan(length(groups),length(nonCingulateRegions));
    %Now do for all groups
    storeGroupCoh = nan(length(groups),length(groups));
    storeGroupVar = nan(length(groups),length(groups));

% Start with each cingulate region
for i = 1:length(groups)

currentColor = colors(i,:);
%get all of the channels within this group

currentGroup = [groups{i}];
groupIndex = find(contains(stimedRegion, currentGroup)==1);

%initialize all of the variables for this group
tempCoords = coords(:,groupIndex);
tempCoh = cohD(groupIndex);
tempVar = var(groupIndex);
tempElectrodeRegions = eRegions(groupIndex);

rightIndex = find(tempCoords(1,:) > 0);
leftIndex = find(tempCoords(1,:) < 0);

count = 1; % keep track of region index

for c = 1:length(regionOrdered) %iterate through the classes on first half of circle (right side)

    currentClass = regionOrdered(c);

    plotIndex = find(ismember(nonCingulateClasses , currentClass)==1);

    regionList = nonCingulateRegions(plotIndex);

    for r = 1:length(regionList)
    
        currentRegion = regionList(r);
        regionIndex = find(contains(tempElectrodeRegions, currentRegion));

        leftCoh = tempCoh(intersect(leftIndex,regionIndex));

        if ~isempty(leftCoh)
            storeCohDLeft(i,count) = mean(leftCoh);
        end

        rightCoh = tempCoh(intersect(rightIndex,regionIndex));
        if ~isempty(rightCoh)
            storeCohDRight(i,count) = mean(rightCoh);
        end

        leftVar = tempVar(intersect(leftIndex,regionIndex));
        if ~isempty(leftVar)
            storeVarLeft(i,count) = mean(leftVar);
        end

        rightVar = tempVar(intersect(rightIndex,regionIndex));
        if ~isempty(rightVar)
            storeVarRight(i,count) = mean(rightVar);
        end

    count = count+1;
    end

end



    for g = 1:length(groups)
    
     if g ~= i
        
    tempGroup = [groups{g}];

    groupIDX = find(contains(tempElectrodeRegions,tempGroup));
       groupCoh = tempCoh(groupIDX); %groups should have specific labels for left and right hemisphere.
    groupVar = tempVar(groupIDX);

     if ~isempty(groupCoh) && ~isempty(groupVar)

        storeGroupCoh(i,g) = mean(groupCoh);
        storeGroupVar(i,g) = mean(groupVar);

     end
    
     end


    end
    
    

end
    %concat and scale CohD and Var across entire dataset
    tempCohD= [storeCohDRight,flip(storeCohDLeft,2),storeGroupCoh];
    %scale Coh D to 3 effect sizes
    for i = 1:size(tempCohD,1)

        for j = 1:size(tempCohD,2)
            cur = abs(tempCohD(i,j));

            if cur <= 0.2
                reScale = 0.1;
            elseif cur > 0.2 && cur <= 1
                reScale = 0.75;
            elseif cur > 1
                reScale = 1.5;
            end
            scaleCohD(i,j) = reScale;
        end
    end


    scaleVar = rescale([storeVarRight,flip(storeVarLeft,2),storeGroupVar],.1,1);

    %distribute scaled data into arrays for adjusting opacity and
    %linewidth
    plotOuterCohD = scaleCohD(:,1:length(outer));
    plotOuterVar = scaleVar(:,1:length(outer));

    plotInnerCohD = scaleCohD(:,length(outer)+1:length(outer)+length(inner));
    plotInnerVar = scaleVar(:,length(outer)+1:length(outer)+length(inner));

%%
    %plot lines onto circle
    figure('position',[-1732         112        1376        1187]);

    for i = 1:length(inner)
        currentColor = colors(i,:);
    for j = 1:length(outer)

        if ~isnan(plotOuterCohD(i,j)) && ~isnan(plotOuterVar(i,j))
                target_x = outer(1,j);
                target_y = outer(2,j);
                offset = 8 / 4;
                control_x = (inner(1,i) + target_x) / 2;
                control_y = (inner(2,i) + target_y) / 2 + offset; % Always curve upwards for simplicity
                t = linspace(0, 1, 100);
                bezier_x = (1-t).^2 * inner(1,i) + 2 * (1-t) .* t * control_x + t.^2 * target_x;
                bezier_y = (1-t).^2 * inner(2,i) + 2 * (1-t) .* t * control_y + t.^2 * target_y;
                plot(bezier_x, bezier_y, '-', 'LineWidth', plotOuterCohD(i,j),'Color',[currentColor,plotOuterVar(i,j)]);
                hold on
        end

    end
    end

hold on

for i = 1:length(inner)
currentColor = colors(i,:);

for j = 1:length(inner)

if i ~= j && ~isnan(plotInnerCohD(i,j)) && ~isnan(plotInnerVar(i,j))
    
    xcoord = [inner(1,i), inner(1,j)];
    ycoord = [inner(2,i), inner(2,j)];

    plot(xcoord,ycoord, 'LineWidth',plotInnerCohD(i,j),'Color',[0.5,0.5,.5,.2]); %darken the lines between groups for visibility

    plot(xcoord,ycoord, 'LineWidth',plotInnerCohD(i,j),'Color',[currentColor,plotInnerVar(i,j)]);

    hold on

end

end


end

%% convergent divergent circle


hold on

% Define convergence points for each inner group
convergencePoints = zeros(2, length(inner));

for i = 1:length(inner)
    % Define the convergence point between the inner group and the outer circle
    % This point should lie between the inner point and the center of the outer group
    convergencePoints(1, i) = (inner(1, i) + mean(outer(1, :))) / 2;
    convergencePoints(2, i) = (inner(2, i) + mean(outer(2, :))) / 2;
end

for i = 1:length(inner)
    currentColor = colors(i,:);

    % Draw a single line from the inner point to the convergence point
    plot([inner(1,i), convergencePoints(1,i)], [inner(2,i), convergencePoints(2,i)], ...
        '-', 'LineWidth', 2, 'Color', currentColor);
    hold on;

    for j = 1:length(outer)
        if ~isnan(plotOuterCohD(i,j)) && ~isnan(plotOuterVar(i,j))
            target_x = outer(1,j);
            target_y = outer(2,j);

            % Control points for the Bezier curve
            control_x1 = (inner(1,i) + convergencePoints(1,i)) / 2;
            control_y1 = (inner(2,i) + convergencePoints(2,i)) / 2;
            control_x2 = (convergencePoints(1,i) + target_x) / 2;
            control_y2 = (convergencePoints(2,i) + target_y) / 2;

            t = linspace(0, 1, 100);
            bezier_x = (1-t).^3 * inner(1,i) + 3 * (1-t).^2 .* t * control_x1 + ...
                       3 * (1-t) .* t.^2 * control_x2 + t.^3 * target_x;
            bezier_y = (1-t).^3 * inner(2,i) + 3 * (1-t).^2 .* t * control_y1 + ...
                       3 * (1-t) .* t.^2 * control_y2 + t.^3 * target_y;

            plot(bezier_x, bezier_y, '-', 'LineWidth', plotOuterCohD(i,j), ...
                 'Color', [currentColor, plotOuterVar(i,j)]);
            hold on;
        end
    end
end

hold on;

% Draw the inner group connections as before
for i = 1:length(inner)
    currentColor = colors(i,:);

    for j = 1:length(inner)
        if i ~= j && ~isnan(plotInnerCohD(i,j)) && ~isnan(plotInnerVar(i,j))
            xcoord = [inner(1,i), inner(1,j)];
            ycoord = [inner(2,i), inner(2,j)];

            plot(xcoord, ycoord, 'LineWidth', plotInnerCohD(i,j), ...
                 'Color', [0.5, 0.5, 0.5, 0.2]); % Darken the lines between groups for visibility

            plot(xcoord, ycoord, 'LineWidth', plotInnerCohD(i,j), ...
                 'Color', [currentColor, plotInnerVar(i,j)]);

            hold on;
        end
    end
end


    %% plot the circle backbone over the data for visualization

%first half
for i = 1:length(regionOrdered)
    
    currentColor = colormap(i,:);

    currentClass = regionOrdered(i);

    plotIndex = length(find(ismember(nonCingulateClasses , currentClass)==1));

    if i == length(regionOrdered)
        plotIndex = plotIndex+1; %draw to complete the first half circle
    end

    plot(outer(1,lastPointIDX:lastPointIDX+plotIndex),outer(2,lastPointIDX:lastPointIDX+plotIndex), '-', 'Color', currentColor,'LineWidth',15);
    lastPointIDX = lastPointIDX+plotIndex;
    hold on

end


colormap = flip(colormap);
count = 1; %initalize count for color on the second half of the circle
regionOrderedFlip = flip(regionOrdered);

for i = length(regionOrderedFlip)+1:2*length(regionOrderedFlip)
    currentColor = colormap(count,:);
    currentClass = regionOrderedFlip(count);

    plotIndex = length(find(ismember(nonCingulateClasses, currentClass)==1));

    plot(outer(1,lastPointIDX:lastPointIDX+plotIndex),outer(2,lastPointIDX:lastPointIDX+plotIndex), '-', 'Color', currentColor,'LineWidth',15);
    hold on
    lastPointIDX = lastPointIDX+plotIndex;

    count = count + 1;
end
hold on

%complete the circle by drawing to the first index
plot([outer(1,lastPointIDX) outer(1,1)] ,[outer(2,lastPointIDX) outer(2,1)], '-', 'Color', currentColor,'LineWidth',15);
hold on

%plot the points of the inner circle
for i = 1:length(inner)
currentColor = colors(i,:);
plot(inner(1,i), inner(2,i), 'o', 'MarkerFaceColor', currentColor,'MarkerEdgeColor','k','MarkerSize',20);
end

axis equal
axis off
saveas(gcf,'figures/coherence/network.svg')