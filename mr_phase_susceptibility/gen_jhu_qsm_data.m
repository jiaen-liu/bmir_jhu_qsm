function [GREMag,GREPhase,Params]=gen_jhu_qsm_data(data,para,oddeven)
    si=size(data);
    if length(si)>4
        data=combine_dim(data,[5:length(si)]);
    end
    if si(3)>para.n_partitions_nos
        data=data(:,:,idx_truncate(para.n_partitions,...
                                   para.n_partitions_nos),...
                  :,:);
    end
    if nargin<3
        oddeven=0;
    end
    ndym=size(data,5);
    TAng=gen_coordinate(para.snormal(:,1),para.prot);
    % transpose was used for QSM in the previous version
    % TAng=TAng.';
    % The following is more general
    TAng=TAng*[0,1,0;1,0,0;0,0,1];
    Params.sizeVol=[para.nr,para.np,para.n_partitions_nos];
    Params.voxSize=[para.resr,para.resp,para.ress];
    try
        Params.B0=para.freq/42.58e6;
    catch me
        Params.B0=para.frequency/42.58e6;
    end
    Params.TR=para.tr*1e-3;
    Params.TAng=TAng;
    Params.DynamicNum=ndym;
    Params.coilNum=1;
    Params.coilName={'None'};
    Params.nEchoes=size(data,4);
    Params.fov=[para.fovr,para.fovp,para.sthickness];
    
    Params.TEs=col(para.te_contr)*1e-3;
    Params.nDynamics=ndym;
    Params.SliceOriSave=1;
    GREMag=abs(data);
    if oddeven
        for i=1:ndym
            data_pha_crct=data(:,:,:,:,i);
% $$$             data_pha_crct=combine_dim(data_pha_crct,[2,3]);
% $$$             data_pha_crct=permute(data_pha_crct,[1,3,2]);
% $$$             ref_pha=dpOddEven(data_pha_crct,2);
            ref_pha=dpOddEven_map(data_pha_crct,2);
            data(:,:,:,1:2:end,i)=data(:,:,:,1:2:end,i)./...
                exp(1i*ref_pha/2);
            data(:,:,:,2:2:end,i)=data(:,:,:,2:2:end,i).*...
                exp(1i*ref_pha/2);
        end
    end
    GREPhase=angle(data);
end