% History
% 20221004: Fix a problem when only one slice is provided, the output is not expected.
function nii=siem_to_nifti(fn,dat,para,read4all,min_inplane_rot,no_save)
    
% only support 3d now
% $$$     if para.dimen~=3
% $$$         error('*** Only support 3D acquisition now! ***');
% $$$     end
    if nargin<4
        read4all=0;
    end
    if nargin<5
        min_inplane_rot=0;
    end
    if nargin<6
        no_save=0;
    end
    is3d=1;
    trep=para.tr/1e3*para.n_interleaves*...
         para.n_partitions;
    if para.dimen==3 && size(dat,3)>para.n_partitions_nos
        dat=dat(:,:,idx_truncate(para.n_partitions,...
                                 para.n_partitions_nos),...
                :,:,:,:,:);
    end
    % generate a template with the data
    
    prot=para.prot;
    snor=para.snormal;
    pfov=[para.fovr;para.fovp];
    spos=[para.x_shift(:),para.y_shift(:),para.z_shift(:)].';

    if min_inplane_rot
        cprot=mod(prot,pi/2);
        if abs(cprot) > pi/4
            cprot=cprot-sign(cprot)*pi/2;
        end
        dprot=cprot-prot;
        dnrot=round(dprot/(pi/2));
        if dnrot < 0 
            dnrot=dnrot+4;
        end;
        % apply the rotation to the data
        dat=rot90(dat,dnrot);
        % swap pfov if x and y are swapped
        if any(dnrot==[1,3])
            pfov=[pfov(2);pfov(1)];
        end
    else
        cprot=prot;
    end
    [quat,qfac,rp]=rotmat_to_quaternion(snor(:,1),...
                                        cprot);
    % dim
    si=size(dat);
    if numel(si)<3
        si(3)=1;
    end
    ndim=numel(si);
    dim=ones(8,1);
    dim(1)=ndim;
    dim(2:ndim+1)=si;
    
    % pixdim
    pixdim=zeros(8,1);
    pixdim(1)=qfac;
    pixdim(2:3)=pfov./dim(2:3);
    pixdim(4)=para.ress;
    pixdim(5)=trep;
    %
    qform_code=1;
    %
    sform_code=0;
    %
    quatern_b=quat(2);
    quatern_c=quat(3);
    quatern_d=quat(4);
    %
    rps=rp;
    for i=1:3
        rps(i,:)=rps(i,:)*pixdim(i+1);
    end
    % compute the position of the corner voxel relative to the slice center in rps coordinates
    inpln=zeros(3,1);
    inpln(1)=inpln(1)+(-dim(2)/2.0+0.5);
    inpln(2)=inpln(2)+(-dim(3)/2.0+0.5);
    % adjust the corner voxel location for 3D
    if is3d 
        inpln(3)=inpln(3)+(-dim(4)/2+0.5);
    end
    inpln=inpln.*pixdim(2:4);
    % account for the position relative to isocenter ('slice offset')
    pos=(spos(:,1)+spos(:,end))/2;
    pos(1:2)=-pos(1:2);
    inplnxyz=rp.'*inpln;
    pos=pos+inplnxyz;
    rps(3,:)=rps(3,:)*qfac;
    %
    qoffset_x=pos(1);
    qoffset_y=pos(2);
    qoffset_z=pos(3);
    srow_x=[rps(:,1);pos(1)];
    srow_y=[rps(:,2);pos(2)];
    srow_z=[rps(:,3);pos(3)];
    nii=make_nii(dat);
    % modify the template
    nii.hdr.dime.dim=dim;
    nii.hdr.dime.pixdim=pixdim;
    nii.hdr.hist.qform_code=qform_code;
    nii.hdr.hist.sform_code=sform_code;
    nii.hdr.hist.quatern_b=quatern_b;
    nii.hdr.hist.quatern_c=quatern_c;
    nii.hdr.hist.quatern_d=quatern_d;
    nii.hdr.hist.qoffset_x=qoffset_x;
    nii.hdr.hist.qoffset_y=qoffset_y;
    nii.hdr.hist.qoffset_z=qoffset_z;
    nii.hdr.hist.srow_x=srow_x;
    nii.hdr.hist.srow_y=srow_y;
    nii.hdr.hist.srow_z=srow_z;
    nii.hdr.dime.scl_slope=1;
    nii.hdr.dime.scl_inter=0;
    % save data
    if ~no_save
        save_nii(nii,fn);
        if read4all
            file_permission(fn,'+rw','ugo');
        end
    end

end
