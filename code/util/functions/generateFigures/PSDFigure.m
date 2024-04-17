function figureOut = PSDFigure(inputStruct,fb,titles)

%input should be a struct containing a 3D matrix chans x signal x trial




screenSize = get(0,'screensize');
screenSize(3:4) = screenSize(3:4)*0.9;
figureOut = figure('Position',screenSize);






currData1 = log(inputStruct.baseline);
currData2 = log(inputStruct.fullscreen);
[rows,columns,numChans] = getSubplotDimensions(size(currData1,1));


for i = 1:numChans
subP(i) = subplot(rows,columns,i);




meanTrace1 = squeeze(mean(currData1(i,:,:),3));

seTrace1 = std(currData1(i,:,:),0,3)/sqrt(size(currData1,3));



plot(fb,meanTrace1,'Color','k')
hold on
jbfill(fb, meanTrace1+seTrace1,meanTrace1-seTrace1, 'k','k', 1, 0.2);
hold on

meanTrace2 = squeeze(mean(currData2(i,:,:),3));

seTrace2 = std(currData2(i,:,:),0,3)/sqrt(size(currData2,3));

plot(fb,meanTrace2,'Color','r')
hold on
jbfill(fb, meanTrace2+seTrace2,meanTrace2-seTrace2, 'r','r', 1, 0.2);
hold on


ylabel('Log Power (dB)')
box off
title(string(titles(i)))



end
