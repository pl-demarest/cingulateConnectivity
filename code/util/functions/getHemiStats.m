function tableOut = getHemiStats(tableIn, conditionTableIn, dataIn, fieldIn, inclusionArray)
%takes in a table of class regions, and effective connectivity of dataset
%to return a table containing statistical comparisons of hemispheric
%differences between major region classes
data = dataIn.(fieldIn);
data(~inclusionArray) = nan;


classList = unique(tableIn.Class);
stimulated = unique(conditionTableIn.Class);


%logical arrays for left-side stimulation
LStim = contains([dataIn.stimulatedRegion{:}],'_lh_');
RStim = contains([dataIn.stimulatedRegion{:}],'_rh_');

%logical arrays for right-side stimulation
LHem = dataIn.electrodeCoordinates(1,:) < 0;
RHem = dataIn.electrodeCoordinates(1,:) > 0;

%iterate through each stimulation condition
count = 1;
for i = 1:length(stimulated)


    curStim = stimulated(i);
    curStimRegions = ismember(conditionTableIn.Class,curStim);


    %iterate through each class

    for ii = 1:length(classList)
    
        curClass = classList(ii);
        curClassRegions = ismember(tableIn.Class,curClass);
        
        curRegions = contains([dataIn.stimulatedRegion{:}], conditionTableIn.Name(curStimRegions)) & contains([dataIn.electrodeRegionLabel{:}], tableIn.Name(curClassRegions));
        %generate logical array for ipsilateral comparisons
        ipsiLIDX = LHem & LStim & inclusionArray & curRegions;
        ipsiRIDX = RHem & RStim & inclusionArray & curRegions;

        %generate logical array for contralateral comparisons
        contraLIDX = RHem & LStim & inclusionArray & curRegions;
        contraRIDX = LHem & RStim & inclusionArray & curRegions;
        
        if (sum(ipsiLIDX) <= 1) || (sum(ipsiRIDX) <= 1)
        iP = nan;
        else
        iP = ranksum(data(ipsiLIDX),data(ipsiRIDX));
        end

        if (sum(contraLIDX) <= 1) || (sum(contraRIDX) <= 1)
        cP = nan;
        else
        cP = ranksum(data(ipsiLIDX),data(ipsiRIDX));
        end
        
        
        tableOut(count).Class = curClass;
        tableOut(count).Condition = curStim;
        tableOut(count).IpsiDifference = abs(nanmean(data(ipsiRIDX))) - abs(nanmean(data(ipsiLIDX)));
        tableOut(count).ipsiRightHemMean = nanmean(data(ipsiRIDX));
        tableOut(count).ipsiLeftHemMean = nanmean(data(ipsiLIDX));

        if nanmean(data(ipsiRIDX))*nanmean(data(ipsiLIDX)) > 0
            tableOut(count).directionChangeI = 0;
        elseif nanmean(data(ipsiRIDX))*nanmean(data(ipsiLIDX)) < 0
            tableOut(count).directionChangeI = 1;
        else
            tableOut(count).directionChangeI = nan;
        end
        
        tableOut(count).IpsiSignificance = iP;
        tableOut(count).IpsiRightCount = sum(ipsiRIDX);
        tableOut(count).IpsiLeftCount = sum(ipsiLIDX);

        %
        tableOut(count).contraDifference = nanmean(data(contraRIDX)) - nanmean(data(contraLIDX));
        tableOut(count).contraRightHemMean = nanmean(data(contraRIDX));
        tableOut(count).contraLeftHemMean = nanmean(data(contraLIDX));

        if nanmean(data(contraRIDX))*nanmean(data(contraLIDX)) > 0
            tableOut(count).directionChangeC = 0;
        elseif nanmean(data(contraRIDX))*nanmean(data(contraLIDX)) < 0
            tableOut(count).directionChangeC = 1;
        else
            tableOut(count).directionChangeC = nan;
        end
        
        tableOut(count).contraSignificance = cP;
        tableOut(count).contraRightCount = sum(contraRIDX);
        tableOut(count).contraLeftCount = sum(contraLIDX);

        count = count+1;

    end



end


end