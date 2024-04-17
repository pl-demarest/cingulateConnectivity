function regionalRepresentation = getRegionsInClusters(input,verbose)

% for a given cell array, containing cell arrays containing unique strings
% that exist within a predetermined set of clusters, return a set of
% cluster ids that each unique string appears in

%in the context of CCEPS clusters- get a cell containing all channel names
%belonging to a cluster, and  then return the cluster IDs that each unique
%channel name appears in. This is useful to compare how anatomical labels
%differentially appear in our data.

% Given cell array
cellData = input;

% Concatenate all the cells to get a list of all strings
allStrings = vertcat(cellData{:});

% Get unique strings
uniqueStrings = unique(allStrings);

% Initialize an empty structure for storing the results
regionalRepresentation = struct();

% For each unique string, find in which sub-cell(s) it occurs
for i = 1:length(uniqueStrings)
    str = uniqueStrings{i};
    occurrences = find(cellfun(@(x) any(strcmp(x, str)), cellData));
    
    % Store the occurrences in the structure
    regionalRepresentation.(matlab.lang.makeValidName(str)) = occurrences;
end

% Display the results
if strcmp(verbose,'true')
disp(regionalRepresentation);
end
end

