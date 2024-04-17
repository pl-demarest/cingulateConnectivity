function VERA = switchVERAChannels(VERA,switchFrom,switchTo)

a = VERA.electrodeLabels(switchFrom);
b = VERA.electrodeDefinition.Annotation(switchFrom);
c = VERA.electrodeDefinition.Label(switchFrom);
d = VERA.electrodeDefinition.DefinitionIdentifier(switchFrom);
e = VERA.electrodeNames(switchFrom);
f = VERA.tala.electrodes(switchFrom,:); 
g = VERA.tala.activations(switchFrom);
h = VERA.tala.trielectrodes(switchFrom,:); 
i = VERA.SecondaryLabel(switchFrom);

j = VERA.electrodeLabels(switchTo); 
k = VERA.electrodeDefinition.Annotation(switchTo) ;
l = VERA.electrodeDefinition.Label(switchTo);
m = VERA.electrodeDefinition.DefinitionIdentifier(switchTo);
n = VERA.electrodeNames(switchTo);
o = VERA.tala.electrodes(switchTo,:); 
p = VERA.tala.activations(switchTo);
q = VERA.tala.trielectrodes(switchTo,:);
r = VERA.SecondaryLabel(switchTo);

shiftNum = length(switchTo)-length(switchFrom);

fromCount =  1;
for from = switchFrom(1) : switchFrom(1) + length(switchTo) -1

VERA.electrodeLabels(from) = j(fromCount);
VERA.electrodeDefinition.Annotation(from) = k(fromCount);
VERA.electrodeDefinition.Label(from) = l(fromCount);
VERA.electrodeDefinition.DefinitionIdentifier(from) = m(fromCount);
VERA.electrodeNames(from) = n(fromCount);
VERA.tala.electrodes(from) = o((fromCount)); 
VERA.tala.activations(from) = p(fromCount);
VERA.tala.trielectrodes(from) = q(fromCount); 
VERA.SecondaryLabel(from) = r(fromCount);

fromCount = fromCount +1;
end

for shift = switchFrom(end):switchTo(1)-1

VERA.electrodeLabels(shift) = VERA.electrodeLabels(shift+1);
VERA.electrodeDefinition.Annotation(shift) = VERA.electrodeDefinition.Annotation(shift+1) ;
VERA.electrodeDefinition.Label(shift) = VERA.electrodeDefinition.Label(shift+1);
VERA.electrodeDefinition.DefinitionIdentifier(shift) = VERA.electrodeDefinition.DefinitionIdentifier(shift+1);
VERA.electrodeNames(shift) = VERA.electrodeNames(shift+1);
VERA.tala.electrodes(shift) = VERA.tala.electrodes(shift+1); 
VERA.tala.activations(shift) = VERA.tala.activations(shift+1);
VERA.tala.trielectrodes(shift) = VERA.tala.trielectrodes(shift+1); 
VERA.SecondaryLabel(shift) = VERA.SecondaryLabel(shift+1);

end

toCount = 1;
for to = switchTo(1)-1:switchTo(end)

VERA.electrodeLabels((to)) = a(toCount);
VERA.electrodeDefinition.Annotation((to)) = b(toCount);
VERA.electrodeDefinition.Label((to)) = c(toCount);
VERA.electrodeDefinition.DefinitionIdentifier((to)) = d(toCount);
VERA.electrodeNames((to)) = e(toCount);
VERA.tala.electrodes((to)) = f((toCount)); 
VERA.tala.activations((to)) = g(toCount);
VERA.tala.trielectrodes((to)) = h(toCount); 
VERA.SecondaryLabel((to)) = i(toCount);

toCount = toCount+1;
end

end