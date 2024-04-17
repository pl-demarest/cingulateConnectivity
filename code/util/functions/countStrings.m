function counts = countStrings(master_list, unique_strings)

% count the number of times a unique string occurs in a list.
    num_unique = length(unique_strings);
    counts = zeros(1, num_unique); % Initialize count array

    for i = 1:num_unique
        counts(i) = sum(strcmp(master_list, unique_strings{i}));
    end
end