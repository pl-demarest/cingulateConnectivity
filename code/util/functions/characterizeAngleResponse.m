function v = characterizeAngleResponse(rawData, window, thresh, nPeaks, vis)
%validate parameters
arguments
    rawData (:,1);
    window (2,1);
    thresh (1,1) uint8;
    nPeaks (1,1) uint8;
    vis (1,1) logical = false;
end
%return nans if window is nan
if any(isnan(window))
    v = NaN(1, 2);
    return
end

maxD = [1, 0];
minD = [1, 0];

%arbitrary initial size, will grow if there are more peaks
allPeaks = NaN(10, 2); 
minY = abs(thresh(1));
maxY = inf;

data = rawData(window(1):window(2));
counter = 1;
for i = 1:length(data)
    if data(i) > maxD(2) %new max
        if maxD(1) < minD(1) %switched
            %store min then reset
            if (abs(minD(2)) >= minY) && (abs(minD(2)) <= maxY)
                %significant
                allPeaks(counter,:) = minD;
                counter = counter + 1;
            end
            %reset regardless
            minD(2) = 0;
        end
        maxD(1) = i;
        maxD(2) = data(i);
    elseif data(i) < minD(2) %new min
        if minD(1) < maxD(1) %switched
            %store max then reset
            if (abs(maxD(2)) >= minY) && (abs(maxD(2)) <= maxY)
                allPeaks(counter,:) = maxD;
                counter = counter + 1;
            end
            maxD(2) = 0;
        end
        minD(1) = i;
        minD(2) = data(i);
    end
end

validI = ~isnan(allPeaks);
validPeaks = allPeaks(validI(:,1),:);
sV = sortrows(validPeaks, 2, "descend",'ComparisonMethod','abs');
%generate output of equal size given by nPeaks
if size(sV, 1) > nPeaks
    v = sV(1:nPeaks, :);
elseif size(sV, 1) < nPeaks
    v = [sV; NaN(nPeaks - size(sV, 1),2)];
else
    v = sV;
end

if vis==true
    %visualize results
    close all
    figure('Position',[0 960 2560 400])
    plot(rawData)
    hold on
    %xline(1800)
    xline(window(1), 'r--')
    xline(window(2), 'r--')
    scatter(allPeaks(:,1)+window(1), allPeaks(:,2))
    scatter(v(:,1)+window(1), v(:,2), 'black','x')
end
end
