function [r_dist,pairs]=getCoherenceForAllChannels(signal,f_corr,N)

n=size(signal,3);
if(nargin < 3)
    N=n*(n-1)/2;
end
r_dist=zeros(N,size(signal,2));

[p, q] = meshgrid(1:n, 1:n);
mask   = triu(ones(n), 1) >+ 0.5;
pairs  = [p(mask) q(mask)];

parfor ch=1:size(signal,2)
    for i=1:N
        r_dist(i,ch)=f_corr(signal(:,ch,pairs(i,1)),signal(:,ch,pairs(i,2)));
    end
end

end