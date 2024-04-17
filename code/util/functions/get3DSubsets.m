function [subAnnotation, subsetCortex] = get3DSubsets(labels,cortex, annotation)

%find strings not included
targets= find(cellfun(@(x)any(strcmp(x,unique(string(labels)))),{annotation.AnnotationLabel.Name}));
targetids=[annotation.AnnotationLabel(targets).Identifier];
subsetCortex.vert=[];
subsetCortex.tri=[];

for i=1:length(targetids)
    triang=cortex.tri(any(cortex.tri == targetids(i),2),:);
    subsetCortex.tri=[subsetCortex.tri; triang-min(triang(:))+1+size(subsetCortex.vert,1)];
    subsetCortex.vert=[subsetCortex.vert; cortex.vert(any(cortex.tri == targetids(i),2),:)];
end

subAnnotation.Annotation=annotation.Annotation(any(annotation.Annotation == targetids,2));
subAnnotation.AnnotationLabel=annotation.AnnotationLabel(targets);

end