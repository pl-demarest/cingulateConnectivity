clear
addpath(genpath(cd))
load('data/pooledData.mat')
load("code/dependencies/cingulateID.mat") % anatomical IDs of cingulate cortex channels
labelTable = readtable("code/dependencies/labelTable.txt"); % table containing all relevant info for anatomical atlas
load("code/dependencies/SEEGClinical22ChanLoc_xyz.mat") % EEG Channel Info
load("code/dependencies/mniMRI.mat")
regionIDX = find(ismember(labelTable.Var1,cingulateID));
regionNames = {labelTable.Var2{regionIDX}}';
%% Group data by region stimulated (ACC, MCC, PCC)
rightACC = {'ctx_rh_G_and_S_cingul-Ant','wm_rh_G_and_S_cingul-Ant'};
leftACC = {'ctx_lh_G_and_S_cingul-Ant','wm_lh_G_and_S_cingul-Ant'};

rightMCC = {'ctx_rh_G_and_S_cingul-Mid-Ant','ctx_rh_G_and_S_cingul-Mid-Post','wm_rh_G_and_S_cingul-Mid-Ant','wm_rh_G_and_S_cingul-Mid-Post'};
leftMCC = {'ctx_lh_G_and_S_cingul-Mid-Ant','ctx_lh_G_and_S_cingul-Mid-Post','wm_lh_G_and_S_cingul-Mid-Ant','wm_lh_G_and_S_cingul-Mid-Post'};

rightPCC = {'ctx_rh_G_cingul-Post-dorsal', 'ctx_rh_G_cingul-Post-ventral' , 'wm_rh_G_cingul-Post-dorsal','wm_rh_G_cingul-Post-ventral'};
leftPCC = {'ctx_lh_G_cingul-Post-dorsal','ctx_lh_G_cingul-Post-ventral','wm_lh_G_cingul-Post-dorsal','wm_lh_G_cingul-Post-ventral'};

ACC = [rightACC, leftACC];
MCC = [rightMCC, leftMCC];
PCC = [rightPCC, leftPCC];

aID = labelTable.Var1(ismember(labelTable.Var2,ACC));
aSegment = ismember(mniMRI.segmentation,aID);

mID = labelTable.Var1(ismember(labelTable.Var2,MCC));
mSegment = ismember(mniMRI.segmentation,mID);

pID = labelTable.Var1(ismember(labelTable.Var2,PCC));
pSegment = ismember(mniMRI.segmentation,pID);

aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');

%% Reconstruct cingulate cortex with electrodes
coordinates = pooledData.electrodeCoordinates;
regionArray = [pooledData.electrodeRegionLabel{:}];
%regionArray = cellfun(@(c) c{1}, pooledData.electrodeRegionLabel, 'UniformOutput', false);
includedElectrodesIndex = find(ismember(regionArray,regionNames));
electrodes = coordinates(:,includedElectrodesIndex);
stimulated = pooledData.stimulatedChannels(includedElectrodesIndex);

%electrodes = unique(electrodes);

figure();
a = patch(isosurface(mniMRI.X,mniMRI.Y,mniMRI.Z,smooth3(aSegment),0.5));
isonormals(mniMRI.X,mniMRI.Y,mniMRI.Z,smooth3(aSegment),a)

m = patch(isosurface(mniMRI.X,mniMRI.Y,mniMRI.Z,smooth3(mSegment),0.5));
isonormals(mniMRI.X,mniMRI.Y,mniMRI.Z,smooth3(mSegment),m)

p = patch(isosurface(mniMRI.X,mniMRI.Y,mniMRI.Z,smooth3(pSegment),0.5));
isonormals(mniMRI.X,mniMRI.Y,mniMRI.Z,smooth3(pSegment),p)

hold on

for ch = 1:length(electrodes)

    if stimulated(ch) == 1
        curcolor = 'r';
    else
        curcolor = 'k';
    end

plot3(electrodes(1,ch),electrodes(2,ch),electrodes(3,ch),'o','MarkerFaceColor',curcolor,'MarkerSize',17,'MarkerEdgeColor','none');
hold on
end

for ch = 1:length(electrodes)

    if stimulated(ch) == 1

    plot3(electrodes(1,ch),electrodes(2,ch),electrodes(3,ch),'o','MarkerFaceColor','r','MarkerSize',17,'MarkerEdgeColor','none');
    hold on
    end

end

grid off
set(a,'FaceColor',aColor,'FaceAlpha',0.3,'EdgeAlpha',0);
set(m,'FaceColor',mColor,'FaceAlpha',0.3,'EdgeAlpha',0);
set(p,'FaceColor',pColor,'FaceAlpha',0.3,'EdgeAlpha',0);
axis equal;
axis ([-inf 10 0 inf])
axis off

%% Multiple comparisons corrections
figure;

subplot(2,1,1)
histogram(pooledData.pValue,100,'FaceColor','r','FaceAlpha',0.3)
box off

subplot(2,1,2)
histogram(abs(log(pooledData.pValue(find(pooledData.pValue < 0.05)))),50,'FaceColor','r','FaceAlpha',0.5)
box off

chanTotal = length(pooledData.pValue);
%proportions of sig channels:
numAlpha05 = length(pooledData.pValue(pooledData.pValue<0.05));

alphaBonHof = bonf_holm(pooledData.pValue);
numAlphaBonHof = length(find(alphaBonHof<0.05));

numBonf = length(find(pooledData.pValue < 0.05/chanTotal));

%num significant chans
percentSig = [numAlpha05/chanTotal; numAlphaBonHof/chanTotal; numBonf/chanTotal];

correctedAlpha = 0.05/chanTotal;

fdr = nan([3 chanTotal]);
fdrAll = mafdr(pooledData.pValue,'BHFDR',true);
fdrNorm= mafdr(pooledData.pValue(pooledData.pValue<0.05),'BHFDR',true);
fdrBH = mafdr(alphaBonHof(alphaBonHof<0.05),'BHFDR',true);

fdr(1,1:length(fdrAll)) = fdrAll;
fdr(2,1:length(fdrNorm)) = fdrNorm;
fdr(3,1:length(fdrBH)) = fdrBH;
%fdrBonf = mafdr(pooledData.pValue(pooledData.pValue < correctedAlpha));

fdrmean = [0.418915296588121, 1.917498960941435e-04, 4.121176069973618e-06];
figure;
for i = 1:3
bar(i,percentSig(i),'FaceColor','r','FaceAlpha',1/i,'EdgeColor','none')
hold on
end
box off
ylim([0 1]);
xticks([1:3])
xticklabels({'p < 0.05','Bonf. Step-down','Bonf.'})
set(gca,'fontsize',18)

%%

sigChannelsIDX = find(pooledData.pValue < 0.05/8500);
stimRegion = [pooledData.stimulatedRegion{sigChannelsIDX}];
cohsD = pooledData.cohensD(sigChannelsIDX);
var = pooledData.variance(sigChannelsIDX);
coordinatesSig = pooledData.electrodeCoordinates(:,sigChannelsIDX);
var(isnan(var)) = 0;
chans = nan(566,6,3);

Groups.rhACCcohsD = cohsD(find(ismember(stimRegion,rightACC)));
chans(1:length(Groups.rhACCcohsD),1,:) = coordinatesSig(:,find(ismember(stimRegion,rightACC)))';

Groups.lhACCcohsD = cohsD(find(ismember(stimRegion,leftACC)));
chans(1:length(Groups.lhACCcohsD),4,:) = coordinatesSig(:,find(ismember(stimRegion,leftACC)))';

Groups.rhMCCcohsD = cohsD(find(ismember(stimRegion,rightMCC)));
chans(1:length(Groups.rhMCCcohsD),2,:) = coordinatesSig(:,find(ismember(stimRegion,rightMCC)))';

Groups.lhMCCcohsD = cohsD(find(ismember(stimRegion,leftMCC)));
chans(1:length(Groups.lhMCCcohsD),5,:) = coordinatesSig(:,find(ismember(stimRegion,leftMCC)))';

Groups.rhPCCcohsD = cohsD(find(ismember(stimRegion,rightPCC)));
chans(1:length(Groups.rhPCCcohsD),3,:) = coordinatesSig(:,find(ismember(stimRegion,rightPCC)))';

Groups.lhPCCcohsD = cohsD(find(ismember(stimRegion,leftPCC)));
chans(1:length(Groups.lhPCCcohsD),6,:) = coordinatesSig(:,find(ismember(stimRegion,leftPCC)))';

Groups.rhACCvar = var(find(ismember(stimRegion,rightACC)));
Groups.lhACCvar = var(find(ismember(stimRegion,leftACC)));
Groups.rhMCCvar = var(find(ismember(stimRegion,rightMCC)));
Groups.lhMCCvar = var(find(ismember(stimRegion,leftMCC)));
Groups.rhPCCvar = var(find(ismember(stimRegion,rightPCC)));
Groups.lhPCCvar = var(find(ismember(stimRegion,leftPCC)));
%%
fns = fieldnames(Groups);

cluster = struct;

for g = 1:length(fns)

curDat = Groups.(fns{g});
curDat = curDat(~isnan(curDat));

clustersOut = oneDCluster(curDat, 30, 1 , 40, 'percentage', .8, fns{g});

cluster.(fns{g}) = clustersOut;

close all

end

save('data/clustering.mat','cluster', '-v7.3');

%% scatterplots
x = nan(566,6);
y = nan(566,6);
groupFNS = fieldnames(Groups);


x(1:length(Groups.rhACCcohsD),1) = Groups.rhACCcohsD;
x(1:length(Groups.lhACCcohsD),4) = Groups.lhACCcohsD;
x(1:length(Groups.rhMCCcohsD),2) = Groups.rhMCCcohsD; 
x(1:length(Groups.lhMCCcohsD),5) = Groups.lhMCCcohsD; 
x(1:length(Groups.rhPCCcohsD),3) = Groups.rhPCCcohsD; 
x(1:length(Groups.lhPCCcohsD),6) = Groups.lhPCCcohsD; 

y(1:length(Groups.rhACCvar),1) = Groups.rhACCvar;
y(1:length(Groups.lhACCvar),4) = Groups.lhACCvar;
y(1:length(Groups.rhMCCvar),2) = Groups.rhMCCvar; 
y(1:length(Groups.lhMCCvar),5) = Groups.lhMCCvar;
y(1:length(Groups.rhPCCvar),3) = Groups.rhPCCvar; 
y(1:length(Groups.lhPCCvar),6) = Groups.lhPCCvar; 

titles = {'rightACC','rightMCC','rightPCC','leftACC','leftMCC','leftPCC'};
%%
figure;
for i = 1:6

    if i == 1 || i ==4
        currentColor=getColors('lush lilac');
    elseif i == 2 || i==5
        currentColor=getColors('celadon porcelain');
    elseif i == 3 || i == 6
        currentColor=getColors('lago blue');
    end
X = x(:,i);
X = X(~isnan(X));
Y = y(:,i);
Y = Y(~isnan(Y));

subplot(2,3,i)
scatter(X,Y,'black','filled','MarkerFaceAlpha',0.4,"MarkerEdgeColor","none",'MarkerFaceColor',currentColor)
hold on

[R, P] = corr(X,Y,'Type','Spearman');
[PermP,c_v]=calcPLevel(X,Y,R,1000,@(X,Y) corr(X,Y,'Type','Spearman'));

text1 = ['Spearman''s Rho = ' num2str(round(double(R),2))];
if PermP < 0.01
text2 = ['p-Value < 0.01'];
else
text2 = ['p-Value = ' num2str(round(double(PermP),2))];
end
txt = [text1 newline text2];

hold on
Mdl = fitglm(X,Y);
lin = predict(Mdl,(-1:4)');
plot(-1:4,lin,'color','r','LineWidth',2);
ylabel('Var','fontsize',20)
xlabel('Cohs D','fontsize',20)
xlim([-1 4])
ylim([-0.2 .3])
text(-1,.25,txt,'fontsize',12,'FontWeight','bold');
set(gca,'linewidth',.8, 'FontSize',18)
box off
clear X Y

end

%%

pairs = [1,4;2,5;3,6];

figure;

ylabel('Var','fontsize',20)
xlabel('Cohs D','fontsize',20)
xlim([-1 4])
ylim([-0.2 .3])


clear X Y

for i = 1:3
    if i == 1 || i ==4
        currentColor=getColors('lush lilac');
    elseif i == 2 || i==5
        currentColor=getColors('celadon porcelain');
    elseif i == 3 || i == 6
        currentColor=getColors('lago blue');
    end

pair = pairs(i,:);

X = x(:,pair);
Y = y(:,pair);

scatter(X,Y,100,'black','filled','MarkerFaceAlpha',0.3,"MarkerEdgeColor","none",'MarkerFaceColor',currentColor)
hold on
clear X Y
end
set(gca,'linewidth',.8, 'FontSize',18)
box off

%% group data for scatter histogram

% Initialize arrays
x = [];
y = [];
group = [];

% Define the groups based on column pairs
group_pairs = [1, 4; 2, 5; 3, 6];

% Process each group pair
for i = 1:size(group_pairs, 1)
    % Get the non-NaN indices for the current group pair in both dimensions

    xTemp = [matrix1(:,group_pairs(i,1)); matrix1(:,group_pairs(i,2))];
    xTemp2= xTemp(~isnan(xTemp));
    
    yTemp = [matrix2(:,group_pairs(i,1)); matrix2(:,group_pairs(i,2))];
    yTemp2= yTemp(~isnan(yTemp));
    
    groupTemp = ones(length(xTemp2),1)*i;
    % Append the non-NaN data to the arrays
    x = [x; xTemp2];
    y = [y; yTemp2];
    group = [group; groupTemp]; % Create a group array with the group number

    clear xTemp xTemp2 yTemp yTemp2 groupTemp
end

%% glass brain
figure('color','white','Position',[1000         243        1304        1095]);
surf = plot3DModel(gca,cortex);
surf.FaceColor = [100,126,146]/256;
alpha(0.02)
hold on
for i = 1:3

    if i == 1  
        currentColor=getColors('lush lilac');
    elseif i == 2
        currentColor=getColors('celadon porcelain');
    elseif i == 3
        currentColor=getColors('lago blue');
    end


pair = pairs(i,:);

X = x(:,pair);
X = X(:);

tempChans = permute(chans(:,pair,:), [2,1,3]);
tempChans = reshape(tempChans,[],size(chans,3));

numChans = length(X);

normSize = X(:);
normSize(normSize < 0) = min(normSize(normSize > 0));

radiusMin = min(normSize);
radiusMax = max(normSize);

stepSize = (radiusMax-radiusMin)/10;

legendRadii = ([radiusMin:stepSize:radiusMax]+0.5)*1.1;

hold on

for ch = 1:numChans

plotBallsOnVolume(gca,tempChans(ch,:),currentColor,((normSize(ch)+0.5)*1.1),'MarkerEdgeColor','k')
hold on

end


end

%%
regions = unique([pooledData.electrodeRegionLabel{:}])';

