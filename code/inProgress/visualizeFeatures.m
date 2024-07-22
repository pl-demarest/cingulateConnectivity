clear
addpath(genpath(cd))
pooledData = load('data/pooledData.mat');
load("code/dependencies/cingulateID.mat") % anatomical IDs of cingulate cortex channels
labelTable = readtable("code/dependencies/labelTable.txt"); % table containing all relevant info for anatomical atlas
load("code/dependencies/SEEGClinical22ChanLoc_xyz.mat") % EEG Channel Info
load("code/dependencies/mniMRI.mat")
regionIDX = find(ismember(labelTable.Var1,cingulateID));
regionNames = {labelTable.Var2{regionIDX}}';
set(0,'DefaultFigureRenderer','painters')
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

aColor = getColors('lush lilac');
mColor = getColors('celadon porcelain');
pColor = getColors('lago blue');

colors = [aColor;mColor;pColor];

colors2 = [aColor;aColor;mColor;mColor;pColor;pColor];

sigChannelsIDX = find(pooledData.pValue < 0.05/length(pooledData.pValue));
stimRegion = [pooledData.stimulatedRegion{sigChannelsIDX}];

%index groups

idx.lACC = find(ismember(stimRegion,leftACC));
idx.rACC = find(ismember(stimRegion,rightACC));

idx.lMCC = find(ismember(stimRegion,leftMCC));
idx.rMCC = find(ismember(stimRegion,rightMCC));

idx.lPCC = find(ismember(stimRegion,leftPCC));
idx.rPCC = find(ismember(stimRegion,rightPCC));

datIn = pooledData.cohensD(sigChannelsIDX);
datIn(datIn == 0) = nan;
dataToPlot = groupData(datIn,idx);

%%
figure;
for g = 1:size(dataToPlot,2)
current = dataToPlot(:,g);
curColor = colors2(g,:);

ratio(g) = length(find(current ~= 0))/length(current);
bar(g,ratio(g),'FaceColor',curColor,'FaceAlpha',0.4)
hold on
end

set(gca,'linewidth',.75, 'FontSize',24,'FontName','Helvetica')
box off
ylabel('% of Significant Responses')



%
%%
X = 1:size(dataToPlot,2);
offset = 0.05;
groups = [1-offset,1+offset,2-offset,2+offset,3-offset,3+offset];
medianLine = [];

left = [1,3,5];
right = [2,4,6];

figure('position',[72   805   935   479])

vp = violinplot(dataToPlot(:,left),groups(left),'ViolinColor',colors,'ShowData',false,'HalfViolin','left','ShowMedian',false,'EdgeColor',[0,0,0],'ShowBox',false,'Width',0.3,'ViolinAlpha',0.2);
hold on

vp2 = violinplot(dataToPlot(:,right),groups(right),'ViolinColor',colors,'ShowData',false,'HalfViolin','right','ShowMedian',false,'EdgeColor',[0,0,0],'ShowBox',false,'Width',0.3,'ViolinAlpha',0.2);
hold on

for v = 1:length(vp2)
vp(1,v).ViolinPlot.XData = vp(1,v).ViolinPlot.XData-offset;
vp2(1,v).ViolinPlot.XData = vp2(1,v).ViolinPlot.XData+0.05;

vp(1,v).ViolinPlot.EdgeAlpha = 0;
vp2(1,v).ViolinPlot.EdgeAlpha = 0;

vp(1,v).ShowWhiskers = 0;
vp2(1,v).ShowWhiskers = 0;
end

for i = 1:length(groups)
curColor = colors2(i,:);
curMedian = nanmean(dataToPlot(:,i));

swarmchart(groups(i),dataToPlot(:,i)',[],curColor,'filled','MarkerFaceAlpha',0.3);
hold on

if rem(i,2) == 1
    l = groups(i) - 0.1;
    
else
    l = groups(i) + 0.1;
end

plot([l groups(i)],[curMedian curMedian],'Linewidth',2,'Color',curColor)

end

set(gca,'linewidth',.75, 'FontSize',24,'FontName','Helvetica')
ylabel('Coherence (Rho)')
box off

saveas(gcf,'figures/coherence/violin.svg')

%% run basic stats
a = dataToPlot(:,1:2);
m = dataToPlot(:,3:4);
p = dataToPlot(:,5:6);

am = ranksum(a(:),m(:))
ap = ranksum(a(:),p(:))
mp = ranksum(m(:),p(:))

aa = ranksum(dataToPlot(:,1),dataToPlot(:,2))
mm = ranksum(dataToPlot(:,3),dataToPlot(:,4))
pp = ranksum(dataToPlot(:,5),dataToPlot(:,6))
%%

dataToPlot = groupData(pooledData.variance(sigChannelsIDX),idx);

X = 1:size(dataToPlot,2);
offset = 0.05;
groups = [1-offset,1+offset,2-offset,2+offset,3-offset,3+offset];
medianLine = [];

left = [1,3,5];
right = [2,4,6];

figure('position',[72   805   935   479])

vp = violinplot(dataToPlot(:,left),groups(left),'ViolinColor',colors,'ShowData',false,'HalfViolin','left','ShowMedian',false,'EdgeColor',[0,0,0],'ShowBox',false,'Width',0.3,'ViolinAlpha',0.2);
hold on

vp2 = violinplot(dataToPlot(:,right),groups(right),'ViolinColor',colors,'ShowData',false,'HalfViolin','right','ShowMedian',false,'EdgeColor',[0,0,0],'ShowBox',false,'Width',0.3,'ViolinAlpha',0.2);
hold on

for v = 1:length(vp2)
vp(1,v).ViolinPlot.XData = vp(1,v).ViolinPlot.XData-offset;
vp2(1,v).ViolinPlot.XData = vp2(1,v).ViolinPlot.XData+0.05;

vp(1,v).ViolinPlot.EdgeAlpha = 0;
vp2(1,v).ViolinPlot.EdgeAlpha = 0;

vp(1,v).ShowWhiskers = 0;
vp2(1,v).ShowWhiskers = 0;
end

for i = 1:length(groups)
curColor = colors2(i,:);
curMedian = nanmedian(dataToPlot(:,i));

swarmchart(groups(i),dataToPlot(:,i)',[],curColor,'filled','MarkerFaceAlpha',0.3);
hold on

if rem(i,2) == 1
    l = groups(i) - 0.1;
    
else
    l = groups(i) + 0.1;
end

plot([l groups(i)],[curMedian curMedian],'Linewidth',2,'Color',curColor)

end

set(gca,'linewidth',.75, 'FontSize',12,'FontName','Helvetica')
box off

saveas(gcf,'figures/coherence/violinVariance.svg')
