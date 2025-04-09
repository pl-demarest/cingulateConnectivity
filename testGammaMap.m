%% for  figure components of figure 2
clear
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

hipAmyg = [listAmyg,listHip];

regionSort = readtable('code/dependencies/regionCategories.xlsx');
saveDir = 'figures/main/figure2/dependencies/';
mkdir(saveDir);
% initialize variables
leftHStim = contains([pooledData.stimulatedRegion{:}],'_lh_');
rightHStim = contains([pooledData.stimulatedRegion{:}],'_rh_');

leftHRec = pooledData.electrodeCoordinates(1,:) < 0;
rightHRec = pooledData.electrodeCoordinates(1,:) > 0;

% get logical array for significant responses

alpha2 = calculateAlphaThreshold(pooledData.gammaP,0.0001);
significant = (pooledData.gammaP < alpha2) & (abs(pooledData.gammaRho) > 0.1);

stimulated = logical(pooledData.stimulatedChannels);

%create logical arrays for the stimulation conditions
condition.AStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(1));
condition.MStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(2:3));
condition.PStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(4:5));

brainFieldnames = fieldnames(templateBrain.regions);


stimRegion = [pooledData.stimulatedRegion{significant}]; 

%index groups for each subregion of the cingulate
idx.lACC = ismember([pooledData.stimulatedRegion{:}],leftACC);
idx.rACC = ismember([pooledData.stimulatedRegion{:}],rightACC);
idx.lMCC = ismember([pooledData.stimulatedRegion{:}],leftMCC);
idx.rMCC = ismember([pooledData.stimulatedRegion{:}],rightMCC);
idx.lPCC = ismember([pooledData.stimulatedRegion{:}],leftPCC);
idx.rPCC = ismember([pooledData.stimulatedRegion{:}],rightPCC);

%initialize colors
aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');




%% Now repeat for supplemental brain maps-> these will require 3 colors and an alpha value

%conditions
effectSizes = [];
effectVariation = [];
numSubjects = [];
includedRegion = logical([]);
percentSignificant = [];

%normalize cohens D for each condition

for i = 1:length(templateBrain.regionList)
    %find all channels within the brain region
    curRegion = contains([pooledData.electrodeRegionLabel{:}],templateBrain.regionList{i});

    %check number of subjects with coverage in this region
    numSubjects(i) = length(unique(pooledData.subjectID(curRegion)));

    %generate logical arrays for each condition, meeting significance,
    %within current region

    tempACC = condition.AStim & curRegion & significant & ~stimulated;
    tempMCC = condition.MStim & curRegion & significant & ~stimulated;
    tempPCC = condition.PStim & curRegion & significant & ~stimulated;

    effectSizes(i,1) = nanmean(pooledData.gammaRho(tempACC));
    effectSizes(i,2) = nanmean(pooledData.gammaRho(tempMCC));
    effectSizes(i,3) = nanmean(pooledData.gammaRho(tempPCC));

    effectVariation(i,1) = nanstd(pooledData.gammaRho(tempACC));
    effectVariation(i,2) = nanstd(pooledData.gammaRho(tempMCC));
    effectVariation(i,3) = nanstd(pooledData.gammaRho(tempPCC));

        if any(contains(cingulateNamesSimple(1),templateBrain.regionList{i}))
        effectSizes(i,1) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif any(contains(cingulateNamesSimple(2:3),templateBrain.regionList{i}))
        effectSizes(i,2) = nan;%  set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        elseif any(contains(cingulateNamesSimple(4:5),templateBrain.regionList{i}))
        effectSizes(i,3) = nan;% set self-connectivity to 0 in order to visualize relative connectivity of the other two sub-regions
        end

end


templateBrainLeft = getOneSide(templateBrain,'left');
templateBrainLeft = isolatePortionOfModel(templateBrainLeft,'x','less',-15);

templateBrainRight = getOneSide(templateBrain,'right');
templateBrainRight = isolatePortionOfModel(templateBrainRight,'x','less',27);

insulaBool = contains(templateBrain.regionList,regionSort{strcmp(regionSort{:,3},'Insula'),1}); %extract insula fieldnames from table
insulaFieldnames = brainFieldnames(insulaBool); %ensure that fieldnames are ordered accordingly 
%index insula subregions and generate an insula struct
for i = 1:length(insulaFieldnames)
   insulaTemplate.regions.(insulaFieldnames{i}) = templateBrain.regions.(insulaFieldnames{i});
end
insulaTemplateLeft = getOneSide(insulaTemplate,'left');

hipAmygBool = contains(templateBrain.regionList,hipAmyg);%hip/amyg fieldnames already exist in a separate .mat file
hipAmygFieldnames = brainFieldnames(hipAmygBool);

%make new struct for hipp and amyg
for i = 1:length(hipAmygFieldnames)

    hipAmygTemplate.regions.(hipAmygFieldnames{i}) = templateBrain.regions.(hipAmygFieldnames{i});

end
hipAmygTemplate = getOneSide(hipAmygTemplate,'left');


%normalize each row so that maximum alpha can be assigned as between 0.2 and .7
aAlphas = effectSizes(:,1);
aNan = isnan(aAlphas); %store nan values to adjust to grey
aAlphas(isnan(aAlphas)) = 0.8;
[~,~,aColors] = electrodeEffectSizes(aAlphas,getColors('lush lilac gradient'),1.5,4);
aColors(aNan,:) = 0.8;

%First Plot everything for ACC
figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainLeft,aColors);
view([270,0])

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainRight,aColors);
view([270,0])

figure('Position',[281          32        3060        1260]);
insulaColors = aColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulaColors);
view([270,0])

figure('Position',[281          32        3060        1260]);
hipAmygColors = aColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])

figure('Position',[281          32        3060        1260]);
hipAmygColors = aColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])

%MCC
mAlphas = effectSizes(:,2);
mNan = isnan(mAlphas);
mAlphas(isnan(mAlphas)) = 0.8;
[~,~,mColors] = electrodeEffectSizes(mAlphas,getColors('celadon porcelain gradient'),1.5,4);
mColors(mNan,:) = 0.8;

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainLeft,mColors);
view([270,0])

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainRight,mColors);
view([270,0])

figure('Position',[281          32        3060        1260]);
insulmColors = mColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulmColors);
view([270,0])

figure('Position',[281          32        3060        1260]);
hipAmygColors = mColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])

figure('Position',[281          32        3060        1260]);
hipAmygColors = mColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])

%PCC
pAlphas = effectSizes(:,3);
pNan = isnan(pAlphas);
pAlphas(isnan(pAlphas)) = 0.8;
[~,~,pColors] = electrodeEffectSizes(pAlphas,getColors('lago blue gradient'),1.5,4);
pColors(pNan,:) = 0.8;

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainLeft,pColors);
view([270,0])

figure('Position',[281          32        3060        1260]);
[surface] = plotProjectedRegionsOnly(templateBrainRight,pColors);
view([270,0])

figure('Position',[281          32        3060        1260]);
insulpColors = pColors(insulaBool,:);
[surfaceInsula] = plotProjectedRegionsOnly(insulaTemplateLeft,insulpColors);
view([270,0])

figure('Position',[281          32        3060        1260]);
hipAmygColors = pColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-176.4 -90.0])

figure('Position',[281          32        3060        1260]);
hipAmygColors = pColors(hipAmygBool,:);
[surfaceHA] = plotProjectedRegionsOnly(hipAmygTemplate,hipAmygColors);
view([-180.8 73.9])


%% create 3d wiring diagram

figure();
surf = plotProjectedRegionsOnly(templateBrain,[.3,.3,.3]);
for i = 1:length(surf)
surf(i).FaceAlpha = .05;
end
hold on

fns  = fieldnames(idx);
subjects = unique(pooledData.subjectID);

 
    for i = length(fns)


    if i <= 2
        curColor = aColor;

    elseif i >=3 || i <= 4
        curColor = mColor;

    elseif i >=5 || i <= 6
        curColor = pColor;

    end

    curData = idx.(fns{i}) & significant;

    curIDX = find(curData);

    for ii = 1:length(curIDX)
temp = curIDX(ii);
% Extract coordinates of the two points
x_start = pooledData.electrodeCoordinates(1, temp);
y_start = pooledData.electrodeCoordinates(2, temp);
z_start = pooledData.electrodeCoordinates(3, temp);

x_end = pooledData.stimulatedChannelCoord(1, temp);
y_end = pooledData.stimulatedChannelCoord(2, temp);
z_end = pooledData.stimulatedChannelCoord(3, temp);

% Calculate the midpoint with jitter
jitter_factor = 0.2; % Adjust this to control the height of the parabola
mid_x = (x_start + x_end) / 2;
mid_y = (y_start + y_end) / 2;
mid_z = (z_start + z_end) / 2;

% Compute jitter based on the distance between the two points
line_length = norm([x_end - x_start, y_end - y_start, z_end - z_start]);
jitter = jitter_factor * line_length;
mid_z = mid_z + jitter; % Add jitter in the z-direction for the parabolic effect

% Combine points
points = [x_start, y_start, z_start; mid_x, mid_y, mid_z; x_end, y_end, z_end];

% Generate the parameter for interpolation
t = [0, 0.5, 1]; % Parameter values for the three points
tt = linspace(0, 1, 100); % Fine interpolation for smooth curve

% Perform spline interpolation for each dimension
x_interp = spline(t, points(:, 1), tt);
y_interp = spline(t, points(:, 2), tt);
z_interp = spline(t, points(:, 3), tt);

% Plot the result
plot3(x_interp, y_interp, z_interp, 'Color', [curColor, 0.3], 'LineWidth', .7); % Interpolated curve
hold on;




    end
    end
