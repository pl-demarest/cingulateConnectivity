function [surf, balls] = plotProjectedRegions(structIn,colors,eColors,radius,varargin)

regionFNS = fieldnames(structIn.regions);

for f = 1:length(regionFNS)

    curRegion = regionFNS(f);

    t = structIn.regions.(curRegion{:}).tri;
    v = structIn.regions.(curRegion{:}).vert;
    e = structIn.regions.(curRegion{:}).electrodes;
    c = colors(f,:);
    ec = eColors(f,:);


    
    ax = gca;
    surf(f) = trisurf(t,v(:,1),v(:,2),v(:,3),'CDataMapping', 'direct','linestyle', 'none','FaceLighting','gouraud','BackFaceLighting','unlit','AmbientStrength',1,varargin{:});
    hold on
    %light(ax,'Position',[1 0 0],'Style','local');
    %material(ax,'dull');
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

    if isfield(structIn.regions.(curRegion{:}),'effectSize')
        if isfield(structIn.regions.(curRegion{:}),'effectColor')
         s = structIn.regions.(curRegion{:}).effectSize;
         %rescale
         s(s<=0.5) = 0.5;
         s(s>=4) = 4;
         sc = structIn.regions.(curRegion{:}).effectColor;
         for i = 1:length(e)
         plotBallsOnVolume(ax,e(i,:),sc(i,:),s(i));
         hold on
         end
        hold on
        else

         s = structIn.regions.(curRegion{:}).effectSize;
         %rescale
         s(s<=0.5) = 0.5;
         s(s>=4) = 4;
         for i = 1:length(e)
         plotBallsOnVolume(ax,e(i,:),ec,s(i));
         hold on
         end
        hold on

        end
    else
    plotBallsOnVolume(ax,e,ec,radius);
    hold on
    end

end

end