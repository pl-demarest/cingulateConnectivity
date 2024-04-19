function out = getAllBandpassedData(input,samplingRate,stimulusCodes,stimulusConditions,timeBefore,timeAfter)

%set input to be chan x signal
if size(input,1) > size(input,2)
    input = input';
end

%first bandpass

delta = bandPassData(input,1,3,3,samplingRate);%delta
theta = bandPassData(input,4,7,3,samplingRate);%theta
alpha = bandPassData(input,8,12,3,samplingRate);%alpha
beta = bandPassData(input,13,25,4,samplingRate);%beta
lowGamma = bandPassData(input,25,50,4,samplingRate);%lowGamama
broadBandGamma = bandPassData(input,70,170,4,samplingRate);%highGamma
broadBandLF = bandPassData(input,5,40,3,samplingRate);%broadband low frequency

%then take hilbert

dH = getHilbert(delta);
clear delta
tH = getHilbert(theta);
clear theta
aH = getHilbert(alpha);
clear alpha
bH = getHilbert(beta);
clear beta
lgH = getHilbert(lowGamma);
clear lowGamma;
bgH = getHilbert(broadBandGamma);
clear broadBandGamma
blfH = getHilbert(broadBandLF);
clear broadBandLF


%then epoch and store

out.delta = epochData(dH,stimulusCodes,stimulusConditions,timeBefore,timeAfter,samplingRate);
out.theta = epochData(tH,stimulusCodes,stimulusConditions,timeBefore,timeAfter,samplingRate);
out.alpha = epochData(aH,stimulusCodes,stimulusConditions,timeBefore,timeAfter,samplingRate);
out.beta = epochData(bH,stimulusCodes,stimulusConditions,timeBefore,timeAfter,samplingRate);
out.lowGamma = epochData(lgH,stimulusCodes,stimulusConditions,timeBefore,timeAfter,samplingRate);
out.broadbandGamma = epochData(bgH,stimulusCodes,stimulusConditions,timeBefore,timeAfter,samplingRate);
out.broadbandLF = epochData(blfH,stimulusCodes,stimulusConditions,timeBefore,timeAfter,samplingRate);

end