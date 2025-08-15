function [y,dpc]=dpOddEven_map(d,ord,frac,nofit)
% data should have [nx,ny,nz,necho,nch,nacq] format
% here nacq can be number of slices or 
% any dimension that will be averaged
% data should be in image domain
    if nargin<2
        ord=2;
    end
    if nargin<3
        frac=0.3;
    end
    if nargin<4
        nofit=0;
    end
    [nx,ny,nz,necho,nch,nacq]=size(d);
    % first fit the first dimention
    d1=combine_dim(d,[2,3]);
    d1=permute(d1,[1,3,2,4,5]);
    si=size(d1);
    d1=reshape(d1,[si(1),si(2),prod(si)/si(1)/si(2)]);
    [y1]=dpOddEven(d1,1,frac,0);
    % fit 3d phase
    d(:,:,:,1:2:end,:,:)=d(:,:,:,1:2:end,:,:).*...
        exp(-1i*y1/2);
    d(:,:,:,2:2:end,:,:)=d(:,:,:,2:2:end,:,:).*...
        exp(1i*y1/2);
    if nacq>1
        d=combine_dim(d,[5,6]);
    end
    if necho>2
        dprc=sum((d(:,:,:,1:end-2,:).*d(:,:,:,3:end,:)).*...
                 exp(-1i*angle(d(:,:,:,2:end-1,:))).^2,5);
        dprc(:,:,:,2:2:end)=conj(dprc(:,:,:,2:2:end));
    elseif necho==2
        dprc=sum(d(:,:,:,1,:).*...
                 conj(d(:,:,:,2,:)),5);
    end
    dprc=sum(dprc,4);
    dpc=angle(dprc);
    % get a 3d mask
    rms=mean(mean(abs(d).^2,5),4).^0.5;
    [~,thrd]=mask1d(rms);
    mask=rms>thrd;
    x=([1:nx]-(1+nx)/2);
    y=([1:ny]-(1+ny)/2);
    z=([1:nz]-(1+nz)/2);
    c=sphere_harm_model_3d(dpc,x,y,z,ord,mask);
    [x,y,z]=ndgrid(x,y,z);
    y3=reshape(sphere_harm_calc_3d(x,y,z,c),[nx,ny,nz]);
    if necho>2
        y3=y3/2;
    end
    y=y1+y3;
% $$$     d(:,:,:,1:2:end,:,:)=d(:,:,:,1:2:end,:,:).*...
% $$$         exp(-1i*y3/2);
% $$$     d(:,:,:,2:2:end,:,:)=d(:,:,:,2:2:end,:,:).*...
% $$$         exp(1i*y3/2);
end
