%% for  figure components of figure 2
clear all
addpath(genpath(cd))
%%
load('data/pooledBrain.mat');
pooledData = load('data/pooledData.mat');
saveDir = 'figures/main/figure1/';
mkdir(saveDir);

%%
cingulateNamesSimple = {'G_and_S_cingul-Ant'
'G_and_S_cingul-Mid-Ant'
'G_and_S_cingul-Mid-Post'
'G_cingul-Post-dorsal'
'G_cingul-Post-ventral'};

AStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(1));
MStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(2:3));
PStim = contains([pooledData.stimulatedRegion{:}],cingulateNamesSimple(4:5));

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
