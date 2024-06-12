function correlations = getUniqueCorrelations(Set1,Set2)

% where set is observations x time

Set1(isnan(Set1)) = [];
Set2(isnan(Set2)) = [];

numSeries1 = size(Set1, 1);
numSeries2 = size(Set2, 1);  % Initialize with NaNs to identify skipped calculations

% Compute the correlation for each unique pair

Set1(isnan(Set1)) = [];
Set2(isnan(Set2)) = [];

count = 1;
for i = 1:numSeries1
    for j = 1:numSeries2
        if isequaln(Set1,Set2) && (i == j)  % Skip correlation of a series with itself if within the same set
            continue;  % Skip the current iteration
        else
            tempCorr = corr(Set1(i,:)', Set2(j,:)','Type','Spearman');
            correlations(count) = tempCorr;
            count = count+1;
        end
    end
end



end