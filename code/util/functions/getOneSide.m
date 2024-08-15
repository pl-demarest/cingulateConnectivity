function out = getOneSide(in,side)

fns = fieldnames(in.regions);

for f = 1:length(fns)

p = in.regions.(fns{f}).vert;
t = in.regions.(fns{f}).tri;
e = in.regions.(fns{f}).electrodes;

switch side
    case 'left'
nP = find(p(:,1)<0);
eP = find(e(:,1)<0);
    case 'right'
nP = find(p(:,1)>=0);
eP = find(e(:,1)>=0);
end

[out.regions.(fns{f}).vert, out.regions.(fns{f}).tri] = extractSurface(nP,p,t);
out.regions.(fns{f}).electrodes = e(eP,:);

end
