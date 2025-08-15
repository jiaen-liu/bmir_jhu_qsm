function y=file_permission(fn,attrib,user)
    cmd=['chmod ',user,attrib,' ',fn];
    status=system(cmd);
    if status
        warning(['*** Changing file (',...
                 fn,...
                 ') permission failed! ***']);
    end
end