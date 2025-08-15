function y=pass_var_struct(struct_out,struct_in)

    fldn=fieldnames(struct_in);
    nfldn=numel(fldn);
    if isempty(struct_out) || ~isstruct(struct_out)
        y=struct;
    else
        y=struct_out;
    end
    
    for i=1:nfldn
        tmp=getfield(struct_in,fldn{i});
        y=setfield(y,fldn{i},tmp);
% $$$         if ~isstruct(tmp)
% $$$             y=setfield(y,fldn{i},tmp);
% $$$         else
% $$$             y=setfield(y,...
% $$$                        fldn{i},pass_var_struct(...
% $$$                            getfield(y,fldn{i}),tmp));
% $$$         end
    end
end