function [c,eps,epsRel,resi,fit,fit_full]=fitPolyn(data,mask,res,ord)
% data is [nx,ny,...,nm], nm is number of matrix, if none, nm=1
% 
    nd=numel(res);
    si=size(data);
    nx=si(1);
    if isempty(mask)
        mask=true(si(1:nd));
    end
    % o
    monomial=polyns(nd+1,ord);
    nmono=size(monomial,2);
    nm=total(mask);
    
    % x=([0:nx-1]-floor(nx/2))*res(1);
    x=([0:nx-1]-floor(nx/2))/floor(nx/2);
    ny=1;
    nz=1;
    y=[];
    z=[];
    xx=[];
    yy=[];
    zz=[];
    if nd>1
        ny=si(2);
        y=([0:ny-1]-floor(ny/2))/floor(ny/2);
    end
    if nd>2
        nz=si(3);
        z=([0:nz-1]-floor(nz/2))/floor(nz/2);
    end
    n=nx*ny*nz;
    coord=zeros(n,nd);
    switch nd
      case 1
        xx=x(:);
        coord(:,1)=xx;
      case 2
        [xx,yy]=ndgrid(x,y);
        xx=xx(:);
        yy=yy(:);
        coord(:,1)=xx;
        coord(:,2)=yy;
      case 3
        [xx,yy,zz]=ndgrid(x,y,z);
        xx=xx(:);
        yy=yy(:);
        zz=zz(:);
        coord(:,1)=xx;
        coord(:,2)=yy;
        coord(:,3)=zz;
    end
    
    if nargout>5
        coord_full=coord;
        Afull=ones(n,nmono);
        for i=2:nmono
            for j=1:nd
                Afull(:,i)=coord_full(:,j).^...
                    monomial(j+1,i).*Afull(:,i);
            end
        end
    end
    coord=coord(find(mask(:)),:);
    A=ones(nm,nmono);
    for i=2:nmono
        for j=1:nd
            A(:,i)=coord(:,j).^monomial(j+1,i).*A(:,i);
        end
    end
    nmat=numel(data)/n;
    data=reshape(data,[n,nmat]);
    % c=A\data(find(mask(:)),:);
    c=inv(A'*A)*A'*data(find(mask(:)),:);
    resi=zeros(n,nmat);
    fit=A*c;
    resi(find(mask),:)=data(find(mask(:)),:)-fit;
    resi=reshape(resi,[nx,ny,nz,nmat]);
    eps=vecnorm(data(find(mask(:)),:)-fit,2,1);
    epsRel=eps./vecnorm(data(find(mask(:)),:),2,1);
    fittmp=zeros(si);
    fittmp(mask(:))=fit;
    fit=fittmp;
    if nargout>5
        fit_full=Afull*c;
    end
    if ord>0
        switch nd
          case 1
            rx=floor(nx/2)*res(1);
            c=c./col(rx.^(monomial(2,:)));
          case 2
            rx=floor(nx/2)*res(1);
            ry=floor(ny/2)*res(2);
            c=c./col(rx.^(monomial(2,:)).*ry.^monomial(3,:));
          case 3
            rx=floor(nx/2)*res(1);
            ry=floor(ny/2)*res(2);
            rz=floor(nz/2)*res(3);
            c=c./col(rx.^(monomial(2,:)).*ry.^monomial(3,:).*rz.^monomial(4,:));            
        end
        
    end
end