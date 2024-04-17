function [referenced_signal] = ACAR(signal,m_signal)
%ACAR Summary of this function goes here
%   Detailed explanation goes here
referenced_signal = [];
n_ch = size(signal,2);


for i = 1:n_ch
    m_w(i) = find_w(signal(:,i),m_signal);
    referenced_signal(:,i) =  signal(:,i) - m_w(i)*m_signal;
end

end

function [w] = find_w(single_signal,m_signal)
%ACAR Summary of this function goes here
%   Detailed explanation goes here
    
%    w = single_signal'/m_signal';
   w = single_signal\m_signal;
%    w = 1;
   %%
%    figure();
%    plot(single_signal,'b');
%    hold on;
%    plot(m_signal,'r');
%    
%    disp('done');
end

