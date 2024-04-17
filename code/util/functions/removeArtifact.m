function [signal] = removeArtifact(signal,stim_start,win_l)
% remove main stimulation artifact from each trial on each channel
% lawrence crowther mnethod

%we indicate the index of each stim onset, then we will do a two-way
%interpolation to cut and remove. the window length will be small- about
%300uS

% remove artifact
ramp_up = linspace(0,1,win_l*2); % TODO: check this
ramp_down = fliplr(ramp_up);
for j = 1:size(signal,2) % channel
    for i = 1:length(stim_start) % each stimulus
        pre = signal(stim_start(i)-3*win_l+1:stim_start(i)-win_l,j);
        post = signal(stim_start(i)+win_l-1:stim_start(i)+3*win_l-2,j);
        new_period = flipud(pre) .* ramp_down' + flipud(post) .* ramp_up';
        signal(stim_start(i)-floor(win_l):stim_start(i)+ceil(win_l)-1,j) = new_period;
    end
end

end