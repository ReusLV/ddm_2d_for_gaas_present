% Find min and max
max_field=V(1);
min_field=V(1);
for i=1:Nnode
    if(V(i)>max_field)
        max_field=V(i);
    end
    if(V(i)<min_field)
        min_field=V(i);
    end
end

