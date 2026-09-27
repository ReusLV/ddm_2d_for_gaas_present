% function [x_min_bc,x_max_bc]=find_boundaries_1d(x_nodes)
% % Find the node (0,0)

% x_min_bc=min(x_nodes);
% x_max_bc=max(x_nodes);

% return;

function [x_min_bc,y_min_bc,y_max_bc,x_max_bc]=find_boundaries(Nnodes,x_nodes,y_nodes)
    % Find the node (0,0)
    x_min_bc=x_nodes(1);
    x_max_bc=x_nodes(1);
    y_min_bc=y_nodes(1);
    y_max_bc=y_nodes(1);
    for i=1:Nnodes
       if(x_min_bc>x_nodes(i)) 
           x_min_bc=x_nodes(i);
       end
       if(x_max_bc<x_nodes(i)) 
           x_max_bc=x_nodes(i);
       end
       if(y_min_bc>y_nodes(i)) 
           y_min_bc=y_nodes(i);
       end
       if(y_max_bc<y_nodes(i)) 
           y_max_bc=y_nodes(i);
       end
    end
    return;
    