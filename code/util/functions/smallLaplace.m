function [signal] = smallLaplace(signal_orig,ch_locations,distance,excluded_ch,exclusion_radius)
% signal_orig should be in signals x channels
% ch_locations is vera_mat.tala.electrodes
% distance is in units of mm (can try 5 mm)
% excluded_ch = []
% don't define exclusion radius

%SMALL_LAPLACE Summary of this function goes here
%   Detailed explanation goes here
signal=signal_orig;
if(exist('exclusion_radius','var'))
    excluded_ch=[excluded_ch find(pdist2(ch_locations,ch_locations(excluded_ch(1),:)) < exclusion_radius)'];
    excluded_ch=[excluded_ch find(pdist2(ch_locations,ch_locations(excluded_ch(2),:)) < exclusion_radius)'];
    excluded_ch=unique(excluded_ch);
end


for i=1:size(signal_orig,2)
    lap_ch=find(pdist2(ch_locations,ch_locations(i,:)) < distance);
    lap_ch(lap_ch == i)=[];
    if(any(i == excluded_ch))
        signal(:,i)=zeros(size(signal(:,i)));
    else
        lap_ch=setdiff(lap_ch,excluded_ch);
        if(isempty(lap_ch))
            % lets keep monopolar 
        else
            signal(:,i)=signal_orig(:,i) - mean(signal_orig(:,lap_ch),2);
        end
    end
    
end


end






