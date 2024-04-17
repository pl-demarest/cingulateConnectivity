cohOutPCC = getChanChanCoherence(data.PCCMain.SixmA,@(x)corr(x,'Type','spearman'));
cohOutACC = getChanChanCoherence(data.ACCMain.SixmA,@(x)corr(x,'Type','spearman'));
%%
for k = 1:10
rng(40)
CACC = nan(size(cohOutPCC,3),k,length(cohOutACC));

CPCC = nan(size(cohOutPCC,3)-1,k,length(cohOutACC));

for trial = 2:size(cohOutPCC,3)
    [clustersOutACC{trial-1}, CACC(trial-1,:,:)] = kmeans(cohOutACC(:,:,trial),k,'MaxIter',500,'Replicates',3,'OnlinePhase','off','Display', 'iter');
    [clustersOutPCC{trial-1}, CPCC(trial-1,:,:)] = kmeans(cohOutPCC(:,:,trial),k,'MaxIter',500,'Replicates',3,'OnlinePhase','off','Display', 'iter');

    %remake the matrixes for later
    dataACC(:,:,trial-1) = cohOutACC(:,:,trial);
    dataPCC(:,:,trial-1) = cohOutPCC(:,:,trial);
end



clustersOutmatACC = reshape(cell2mat(clustersOutACC),[230,27]);
clustersOutmatPCC = reshape(cell2mat(clustersOutPCC),[230,27]);

newClustersACC = nan(size(clustersOutmatACC));
newClustersPCC = nan(size(clustersOutmatPCC));


referenceClusterACC = clustersOutmatACC(:,1);
referenceClusterPCC = clustersOutmatPCC(:,1);

newClustersACC(:,1) = referenceClusterACC;
newClustersPCC(:,1) = referenceClusterPCC;


uniqueClusterLabels = unique(referenceClusterACC);
uniqueClusterLabelsStore = uniqueClusterLabels;

maxSimACC = nan(1,length(uniqueClusterLabels));
maxSimPCC = nan(1,length(uniqueClusterLabels));
ACCSim = nan(1,length(uniqueClusterLabels));
PCCSim = nan(1,length(uniqueClusterLabels));

count = 0;
for i = 2:size(clustersOutmatACC,2)
    %iterate through each clustering for each trial and re-assign cluster
    %labels to match the similarity score

currentClusterACC = clustersOutmatACC(:,i);
currentClusterPCC = clustersOutmatPCC(:,i);


for label = 1:length(uniqueClusterLabels)

    idxACC1 = find(referenceClusterACC == uniqueClusterLabels(label));
    idxPCC1 = find(referenceClusterPCC == uniqueClusterLabels(label));

    %get the actual data clusters from the reference data
    refClusterACC = dataACC(idxACC1,:,2);
    refClusterPCC = dataPCC(idxPCC1,:,2);

    for label2 = 1:length(uniqueClusterLabels)
    
    idxACC2 = find(currentClusterACC == uniqueClusterLabels(label2));
    idxPCC2 = find(currentClusterPCC == uniqueClusterLabels(label2));

    ACCSim(label2) = mean(pdist2(refClusterACC, dataACC(idxACC2,:,i),'cosine'),'all');
    PCCSim(label2) = mean(pdist2(refClusterPCC, dataPCC(idxPCC2,:,i),'cosine'),'all');

    end
    
winningLabel = find(max(ACCSim) == ACCSim);

idx = find(currentClusterACC == winningLabel);

newClustersACC(idx, i) = winningLabel;

%silhouette(dataACC(:,:,1),newClustersACC(:,1));

maxSimACC(label) = max(ACCSim);
maxSimPCC(label) = max(PCCSim);

end


averageTrialSimACC(i-1) = mean(maxSimACC);
averageTrialSimPCC(i-1) = mean(maxSimPCC);

end

clusterSimACC(k) = mean(averageTrialSimACC);
clusterSimPCC(k) = mean(averageTrialSimACC);

end


%% Try this without trial-trial clustering
cohOutACCNOTrial = getChanChanCoherence(data.ACCMain.SixmA,@(x)corr(x,'Type','spearman'));
%%
newCohMat = nan(size(cohOutACCNOTrial,3)*size(cohOutACCNOTrial,1),size(cohOutACCNOTrial,2));
rowIndex1 = 1;
rowIndex2 = size(cohOutACCNOTrial,2);

for trial = 1:size(cohOutACCNOTrial,3)

currentMatrix = cohOutACCNOTrial(:,:,trial);

newCohMat(rowIndex1:rowIndex2,:) = currentMatrix;

rowIndex1 = rowIndex1 + size(cohOutACCNOTrial,1);
rowIndex2 = rowIndex2 + size(cohOutACCNOTrial,1);
end
