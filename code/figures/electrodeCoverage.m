clear all
addpath(genpath(cd))
load('data/pooledData.mat')
%%

subjects = unique(subjectID);

for i = 1:length(subjects)

sidx = subjectID == subjects(i);


end