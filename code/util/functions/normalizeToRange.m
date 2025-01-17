function normalized = normalizeToRange(data,x,y)

data = normalize(data,'range');
range = y-x;
normalized = (data*range) +x;

end