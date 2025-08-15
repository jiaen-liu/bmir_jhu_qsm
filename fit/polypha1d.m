function [y,c]=polypha1d(d,mask,ord,maskDel,center)
    if isreal(d)
        d=exp(1i*d);
    end
    d=d(:);
    nx=length(d);
% $$$     if nx>60
% $$$         % mask_unrely_pha_del=abs(mask_reliable_phase_1d(d,10))>0.95;
% $$$         mask_unrely_pha=abs(mask_reliable_phase_1d(d,10))>0.8;
% $$$         % maskDel=maskDel & mask_unrely_pha_del;
% $$$         mask=mask & mask_unrely_pha;
% $$$     end
    nm=total(mask);
    if nm<ord+1
        % do not fit if there are not 
        % enough data
        y=zeros(nx,1);
        c=zeros(ord+1,1);
        return;
    end
    if nargin<4
        maskDel=mask;
    end
    ord_del=1;
    if nargin<5
        % define intercept at the center
        center=floor(nx/2);
    end
    intercept=angle(d(center));
    % first fit to the derivative
    
    x=([0:nx-1].'-floor(nx/2))*1/nx;
    % x=([0:nx-1].'-floor(nx/2));
    delta=angle(d(3:end).*conj(d(1:end-2)))/2/(1/nx);
    xdel=x(2:end-1);
    % c=fitPolyn(delta,maskDel(2:end-1),1/nx,ord_del-1);
    
    c=median(delta);
    c=c./[1:ord_del].';
    % add intercept to c because it was not
    % included in the first fit
    c=[intercept-x(center)*c;c];
    if ord>ord_del
        c=[c;zeros(ord-ord_del,1)];
    end
    A=x.^[0:ord];
    y0=A*c;
    % final fit to the residuals
    dif=angle(d./exp(1i*y0));
    cdif=fitPolyn(dif,mask,1/nx,ord);
    c=c+cdif;
    y=A*c;
end