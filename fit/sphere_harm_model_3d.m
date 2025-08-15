function [c,eps,fit,cnorm]=sphere_harm_model_3d(f,x,y,z,ord,mask)
    mask=logical(mask);
    si=size(x);
    if isvector(x)
        [x,y,z]=ndgrid(x,y,z);
    end
    si=size(x);
    nx=si(1);
    ny=si(2);
    if numel(si)<3
        nz=1;
    else
        nz=si(3);
    end
    n=nx*ny*nz;
    nv=numel(f)/n;
    f=reshape(f,[n,nv]);
    if nargin<6
        x=x(:);
        y=y(:);
        z=z(:);
    else
        x=x(mask(:));
        y=y(mask(:));
        z=z(mask(:));
        f=f(mask(:),:);
    end
    if isempty(x)
        c=zeros((ord+1)^2,nv);
        if nargout==2 
            eps=zeros(nx,ny,nz,nv);
        end
        return;
    end
    rmax=max(abs(x.^2+y.^2+z.^2)).^0.5;
    x=x/rmax;
    y=y/rmax;
    z=z/rmax;
    A=gen_spher_harm_poly(x,y,z,ord);
    c=A\f;
    if nargout>=2
        fitm=A*c;
        eps=zeros(n,nv);
        fit=zeros(n,nv);
        eps(mask(:),:)=fitm-f;
        eps=reshape(eps,[nx,ny,nz,nv]);
        fit(mask(:),:)=fitm;
        fit=reshape(fit,[nx,ny,nz,nv]);
        cnorm=c;
        for i=2:(ord+1)^2
            cnorm(i,:)=cnorm(i,:)*norm(A(:,i));
        end
    end
    for i=1:ord
        c((i+1)^2-2*i:(i+1)^2,:)=c((i+1)^2-2*i:(i+1)^2,:)/rmax^i;
    end
end