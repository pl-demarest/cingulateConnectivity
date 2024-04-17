function flat_cell = flattenCell(input_cell)

% Initialize output cell array
flat_cell = cell(size(input_cell));

% Iterate through each element in the cell array
for i = 1:numel(input_cell)

    % If the current cell contains another cell array, recursively call flatten_cell
    if iscell(input_cell{i})
        flat_cell{i} = flatten_cell(input_cell{i});
    else
        % If the current cell does not contain a cell array, assign it directly to the corresponding position in flat_cell
        flat_cell{i} = input_cell{i};
    end

    % If the current cell is still a cell array (i.e., it contained more than one string), just keep the first one
    if iscell(flat_cell{i})
        flat_cell{i} = flat_cell{i}{1};
    end
end
end