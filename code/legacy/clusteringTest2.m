for k = 1:10
    %% generate clusters and central tendencies
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

newClusterOut = nan(size(clustersOutmatPCC));
%% cluster centroids


[centroidClusters, CACC2] = kmeans(reshape(CACC,[size(CACC,1)*size(CACC,2),230]),k,'MaxIter',500,'Replicates',3,'OnlinePhase','off','Display', 'iter');

for trial = 1:size(clustersOutmatACC,2)
    for dataLabel = 1:k

        c1 =  squeeze(CACC(trial,dataLabel,:));
        
        centDifference = nan(k,1);
        for centroidLabel = 1:k


      % compare the centroids of the original data clusters, and the
      % centroids of the centroids to assign labels based on the lowest
      % difference between the two


            cc1 = CACC2(centroidLabel,:)';

            centDifference(centroidLabel) =sqrt(sum((c1 - cc1) .^ 2));



        end
                minCentroidLabel = find(min(centDifference) == centDifference);
                replaceIDX = find(clustersOutmatACC(:,trial) == dataLabel);
                newClusterOut(replaceIDX,trial) = minCentroidLabel;
                
    end


    
end

%% relabel coherence clusters

end


