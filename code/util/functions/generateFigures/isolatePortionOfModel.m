function out = isolatePortionOfModel(in,dimension,thresholdType,threshold)

%taking a 3d model struct,  this functiono will return a new struct that
%only contains values below the above specified threshold. 

fns = fieldnames(in.regions);

for f = 1:length(fns)

p = in.regions.(fns{f}).vert;
t = in.regions.(fns{f}).tri;
e = in.regions.(fns{f}).electrodes;

    % Determine the coordinate index based on the 'dimension' input
    switch dimension
        case 'x'
            dimIdx = 1;
        case 'y'
            dimIdx = 2;
        case 'z'
            dimIdx = 3;
        otherwise
            error('Invalid dimension specified.');
    end

    % Determine the indices based on 'thresholdType' and 'threshold'
    if strcmp(thresholdType, 'greater')
        nP = find(p(:, dimIdx) > threshold);
        eP = find(e(:, dimIdx) > threshold);
    elseif strcmp(thresholdType, 'less')
        nP = find(p(:, dimIdx) < threshold);
        eP = find(e(:, dimIdx) < threshold);
    else
        error('Invalid threshold type specified. Use "greater" or "less".');
    end

[out.regions.(fns{f}).vert, out.regions.(fns{f}).tri] = extractSurface(nP,p,t);
out.regions.(fns{f}).electrodes = e(eP,:);

end

