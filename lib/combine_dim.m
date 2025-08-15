function y=combine_dim(d,dim)
    si=size(d);
    ndim=length(si);
    ndim_c=length(dim);
    si_c=zeros(1,ndim-ndim_c+1);
    
    if dim(1)==1
        si_c(1)=prod(si(dim));
        if dim(2)~=ndim
            si_c(2:end)=si(ndim_c+1:end);
        end
    else
        si_c(1:dim(1)-1)=si(1:dim(1)-1);
        si_c(dim(1))=prod(si(dim));
        if dim(end)~=ndim
            si_c(dim(1)+1:end)=si(dim(end)+1:end);
        end
    end
    y=reshape(d,si_c);
end