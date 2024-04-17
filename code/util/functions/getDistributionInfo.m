function distributionStruct = getDistributionInfo(taskIn, baseIn, trialPairs)

%gets additional information from coherence distributions



for ch = 1:size(taskIn,1)
    task = taskIn(ch,:);
    baseline = baseIn(ch,:);
task(isnan(task)) = [];
baseline(isnan(baseline)) = [];
distributionStruct.cohensD(ch) = computeCohenD(task,baseline,'paired');
distributionStruct.variance(ch) = var(baseline) - var(task);
distributionStruct.pVal(ch) = ranksum(task,baseline);

end

end