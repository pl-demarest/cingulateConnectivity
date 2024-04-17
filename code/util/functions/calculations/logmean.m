function m=logmean(a,b)
if abs(b-a)>1e-3
    m=(b-a)./log(b./a);
else
    m=(a+b)./2;
end