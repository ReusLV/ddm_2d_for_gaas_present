% draw field
cmap=colormap;
[n m]=size(cmap);

Nl=25; % number of field lines equal to the number of colors in palette
delta_l=int8(n/Nl-rem(n,Nl)/Nl);
for i=1:Nl
    cmap1(i,:)=cmap((i-1)*delta_l+1,:);
end

delta_field=(max_field-min_field)/(Nl-1);
for i=1:Nl
   field_lines(i)=min_field+(i-1)*delta_field; 
end

% Colorbar levels
Ncb_level=3;
delta_tick=n/(Ncb_level-1);
delta_cb=(max_field-min_field)/(Ncb_level-1);
for i=1:Ncb_level
    cb_tick(i)=int32((i-1)*delta_tick);
    cb_values(i)=min_field+(i-1)*delta_cb;
end
cb_tick(1)=2;
cb_tick(Ncb_level)=n;
% colorbar('YLim',[min_field max_field],'YTickLabel',cb_values);
% colorbar('ALim',[min_field max_field],'CLim',[min_field max_field],'YLim',[min_field max_field]);
% colorbar('East','YTick',cb_tick,'YTickLabel',cb_values);
% colorbar('North','XTick',cb_tick,'XTickLabel',cb_values,'Color',[0 0 0],'FontSize',14);

% Loop over elements
for i=1:Nel

    % Field values of nodes
    V1=V(el_2d_no(i,1));
    V2=V(el_2d_no(i,2));
    V3=V(el_2d_no(i,3));
      
    if(V1<=V2 & V2<=V3)
        in1=1;
        in2=2;
        in3=3;
    end
    
    if(V1<=V2 & V3<=V2 & V1<=V3)
        in1=1;
        in2=3;
        in3=2;
    end

    if(V1<=V2 & V3<=V2 & V3<=V1)
        in1=3;
        in2=1;
        in3=2;
    end

    if(V2<=V1 & V3<=V2 & V3<=V1)
        in1=3;
        in2=2;
        in3=1;
    end
    
    if(V2<=V1 & V2<=V3 & V1<=V3)
        in1=2;
        in2=1;
        in3=3;
    end
    
    if(V2<=V1 & V2<=V3 & V3<=V1)
        in1=2;
        in2=3;
        in3=1;
    end

    V1=V(el_2d_no(i,in1));
    V2=V(el_2d_no(i,in2));
    V3=V(el_2d_no(i,in3));
    
    x1=x_coords(el_2d_no(i,in1));
    y1=y_coords(el_2d_no(i,in1));
    x2=x_coords(el_2d_no(i,in2));
    y2=y_coords(el_2d_no(i,in2));
    x3=x_coords(el_2d_no(i,in3));
    y3=y_coords(el_2d_no(i,in3));
    
    for j=1:Nl
        if(field_lines(j)>=V1 & field_lines(j)>=V2 & field_lines(j)<=V3)
            ratio=(field_lines(j)-V1)/(V3-V1);
            xt1=x1+ratio*(x3-x1);
            yt1=y1+ratio*(y3-y1);
            ratio=(field_lines(j)-V2)/(V3-V2);
            xt2=x2+ratio*(x3-x2);
            yt2=y2+ratio*(y3-y2);
            % line_plot(xt1,yt1,xt2,yt2,'k',1);
            % line_plot(xt1,yt1,xt2,yt2,cmap1(j,:),1);
            fill([xt1 xt2 x3],[yt1 yt2 y3],cmap1(j,:),'EdgeColor',cmap1(j,:));
        end
        if(field_lines(j)>=V1 & field_lines(j)<=V2 & field_lines(j)<=V3)
            ratio=(field_lines(j)-V1)/(V3-V1);
            xt1=x1+ratio*(x3-x1);
            yt1=y1+ratio*(y3-y1);
            ratio=(field_lines(j)-V1)/(V2-V1);
            xt2=x1+ratio*(x2-x1);
            yt2=y1+ratio*(y2-y1);
            % line_plot(xt1,yt1,xt2,yt2,'k',1);
            % line_plot(xt1,yt1,xt2,yt2,cmap1(j,:),1);
            fill([xt1 xt2 x2 x3],[yt1 yt2 y2 y3],cmap1(j,:),'EdgeColor',cmap1(j,:));
        end
        if(field_lines(j)<=V1 & field_lines(j)<=V2 & field_lines(j)<=V3)
            fill([x1 x2 x3],[y1 y2 y3],cmap1(j,:),'EdgeColor',cmap1(j,:));
            % fill([x1 x2 x3],[y1 y2 y3],cmap1(j,:));
        end
    
    end
end


