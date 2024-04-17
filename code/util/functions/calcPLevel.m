function [p,c_v]=calcPLevel(x,y,rel,iterations,fh,onesided,outp_ind)
if(nargin < 6)
    onesided=0;
end
if(nargin < 7)
    outp_ind=1;
end
%CALCCHANCELEVEL retuns the chance level for x y by randomization
% x... x values
%y... y values
%rel... calculated relationship
% iterations .. number of iterations
%fh .. function handle to convert x y
y_buff=y(:);
c_v=[];
for i=1:iterations
    y_buff=y_buff(randperm(size(y_buff,1)));
    if(outp_ind == 1)
        c_v(i,:)=fh(x,y_buff);
    else
        [~,c_v(i,:)]=fh(x,y_buff);
    end
    
end
%  figure;
%  histogram(c_v)
 if(onesided == 1)
     pd=fitdist(c_v,'HalfNormal');
     p = normcdf(-abs(rel), pd.mu, pd.sigma);
 else
    p = 2*normcdf(-abs(rel), mean(c_v, 1), std(c_v, 0, 1));
 end
end