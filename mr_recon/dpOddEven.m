% 2025-03-05, Jiaen Liu: fix bug in phase wrapping issue
% 2023-04-28, Jiaen Liu: avoid phase wrapping issue at the expected
% reference point (intercept) 
% 2022-10-26, Jiaen Liu: In case 20221013_2 the navigator showed lots of artifact It was due to the mask is too small, modified [y,c]=polypha1d(dpc,maskDel,ord,maskDel); to 
% [y,c]=polypha1d(dpc,mask,ord,maskDel); and added masking criteria
function [y,c,dpc,dpc_2e]=dpOddEven(d,ord,frac,nofit)
% data should have [nx,necho,nch,nacq] format
% here nacq can be number of slices or 
% any dimension that will be averaged
% data should be in image domain
    dpc_2e=[];
    if nargin<2
        ord=2;
    end
    if nargin<3
        frac=0.3;
    end
    if nargin<4
        nofit=0;
    end
    [nr,necho,nch,nacq]=size(d);
    if nacq>1
        d=combine_dim(d,[3,4]);
    end
    rms=squeeze(mean(abs(d(:,1,:)).^2,3).^0.5);
    mask=mask1d(rms,frac);
    if mean(mask)>0.7
        [rmssort]=sort(rms(:));
        thrd=rmssort(floor(length(rmssort)*0.3));
        mask=rms>thrd;
    end
    idx_mask=find(mask);
    span_mask=idx_mask(end)-idx_mask(1);
    rel=0.5;
    while true
        maskDel=mask1d(rms,frac,rel);
        idx_mask_del=find(maskDel);
        span_mask_del=idx_mask_del(end)-idx_mask_del(1);
        if span_mask_del/span_mask>0.4
            break;
        else
            rel=rel-0.05;
        end
    end
    if necho>2
        dprc=sum((d(:,1:end-2,:).*d(:,3:end,:)).*...
                 exp(-1i*angle(d(:,2:end-1,:))).^2,3);
        dprc(:,2:2:end,:)=conj(dprc(:,2:2:end,:));
        dprc_2e=sum(d(:,1:2:floor(necho/2)*2,:).*...
                    conj(d(:,2:2:floor(necho/2)*2,:)),3);
    elseif necho==2
        dprc=sum(d(:,1,:,:).*...
                 conj(d(:,2,:,:)),3);
    end
    dprc=sum(dprc,2);
    dpc=angle(dprc);
    if necho>2
        dprc_2e=sum(dprc_2e,2);
        dpc_2e=angle(dprc_2e);
    end
    % fit
    if ~nofit
        if necho>2
            % avoid phase wrapping issue at the expected
            % reference point (intercept)
            idx_mask=find(mask);
            n_center=min(15,length(idx_mask));
            idx_mask_tmp=idx_mask(1:floor(length(idx_mask)/n_center):end);
            n_center=length(idx_mask_tmp);
            if mod(n_center,2)==0
                n_center=n_center-1;
            end
            idx_mask=idx_mask(1:floor(length(idx_mask)/n_center):end);
            dif=zeros(n_center,1);
            difabs=zeros(n_center,1);
            y=zeros(nr,n_center);
            c=zeros(ord+1,n_center);
            n_wrap_2e=[0].';
            n_wrap=length(n_wrap_2e);
            n_wrap_2e_est=repmat(n_wrap_2e,n_center);
            n_wrap_3e_est=zeros(n_wrap,n_center);
            for i=1:n_center
                [y3e,c3e]=polypha1d(dpc,mask,ord,maskDel,...
                                    idx_mask(i));
                y3e=y3e;
                c3e=c3e;
                y(:,i)=y3e;
                c(:,i)=c3e;
                [y2e,c2e]=polypha1d(dpc_2e,mask,ord,maskDel,...
                                    idx_mask(i));
                for iwrap=1:n_wrap
                    n_wrap_3e_est(iwrap,i)=...
                        mean((2*y2e(mask)+4*pi*n_wrap_2e_est(iwrap)-...
                              y3e(mask))/2/pi);
                end
            end
            % 2025-03-05, Jiaen Liu:
            % there can be an arbitary 2*pi in the y estimation
            n_wrap_median=median(round(n_wrap_3e_est));
            idx_median=find(round(n_wrap_3e_est)==n_wrap_median);
            [~,imin]=min(abs(idx_median-nr/2));
            idx_ref=idx_median(imin);
            % [~,imin]=min(abs(n_wrap_3e_est-round(n_wrap_3e_est)));
            y=y(:,idx_ref)+n_wrap_median*2*pi;
            c=c(:,idx_ref)+n_wrap_median*2*pi;
            y=y/2;
            c=c/2;
        else
            [y,c]=polypha1d(dpc,mask,ord,maskDel);
        end
    else
        y=[];
        c=[];
    end
end
