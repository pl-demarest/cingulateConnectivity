function jaccardSim = computeJaccard(cluster1, cluster2)

%use this to obtain a similarity score between two clusters

    intersection = length(intersect(cluster1, cluster2));
    unionSet = length(union(cluster1, cluster2));
    jaccardSim = double(intersection / unionSet);
end
