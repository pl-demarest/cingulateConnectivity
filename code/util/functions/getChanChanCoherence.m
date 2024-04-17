function [r_dist]=getChanChanCoherence(signal,f_corr)

n=size(signal,3);

r_dist=zeros(size(signal,1),size(signal,1),n);


parfor trial = 1:n

        r_dist(:,:,trial)=f_corr(signal(:,:,trial)');

end

end