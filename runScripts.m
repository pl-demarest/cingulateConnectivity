clear all
addpath(genpath(cd))

run("main.m")
run("extractCoherence.m")
run("extractResponseFeatures.m")
run("extractGamma.m")
run("extractPhase.m")
run("poolData.m")
run("compileData.m")
run("extractInterChanCoherence.m")