function [surf, balls] = plotProjectedRegionsOnly(structIn,colors,varargin)

regionFNS = fieldnames(structIn.regions);

for f = 1:length(regionFNS)

    curRegion = regionFNS(f);

    t = structIn.regions.(curRegion{:}).tri;
    v = structIn.regions.(curRegion{:}).vert;
    e = structIn.regions.(curRegion{:}).electrodes;

    if size(colors,1) == 1
        c = colors;
    else
        c = colors(f,:);
    end

    
    ax = gca;
    surf(f) = trisurf(t,v(:,1),v(:,2),v(:,3),'CDataMapping', 'direct','linestyle', 'none','FaceLighting','gouraud','BackFaceLighting','unlit','AmbientStrength',.5,varargin{:});
    hold on
    %light(ax,'Position',[1 0 0],'Style','local');
    material(ax,'dull');
    set(ax,'AmbientLightColor',[1 1 1]);
    %camlight(ax,'headlight');
    set(ax,'xtick',[]);
    set(ax,'ytick',[]);
    axis(ax,'equal');
    axis(ax,'off');
    xlim(ax,'auto');
    ylim(ax,'auto');
    set(ax,'clipping','off');
    set(ax,'XColor', 'none','YColor','none','ZColor','none')
    surf(f).FaceColor = c;

    set(gca,'CameraViewAngleMode','Manual')

end

end