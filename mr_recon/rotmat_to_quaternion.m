% History
% 20221004: When input is a rotation matrix, tranpose and convert it from DICOM to NIFTI definition (Jiaen Liu)
function [quat,qfac,rp]=rotmat_to_quaternion(normal,rot_inplane)
% $$$ ; New version of rotmat_to_quaternion in dezwart/idl/lib
% $$$ ; based on orientation calculated in siem_coord.pro
% $$$ ;
% $$$ ; Siemens uses [pe,ro,sl] in the sequence, mapping this to
% $$$ ; TRA 0 : [ ap,-rl, fh], 90 : [ rl, ap, sl]   (0 and 90 degree in plane rotations)
% $$$ ; COR 0 : [ rl,-fh, ap], 90 : [ fh, rl, ap]
% $$$ ; Sag 0 : [ ap, fh, rl], 90 : [-fh, ap, rl]
% $$$ ;
% $$$ ; In (our) recon, the images are stored as [-ro,pe,sl], the ro is inverted so 
% $$$ ; that this still forms a right handed system.
% $$$ ; In image space therefor the orientations [dim1,dim2,dim3] map to
% $$$ ; TRA 0 : [  rl, ap, fh], 90 : [ -ap, rl, sl]
% $$$ ; COR 0 : [  fh, rl, ap], 90 : [ -rl, fh, ap]
% $$$ ; Sag 0 : [ -fh, ap, rl], 90 : [ -ap,-fh, rl]
% $$$ ;
% $$$ ; For (double) oblique scans, the zero for in plane rotation 
% $$$ ; is defined by Siemens as the position with the PE lying in the 
% $$$ ; nearest 2-axial plane (at least one of the components of the PE direction is 
% $$$ ; zero without in plane rot). The in plane rotation appears to be a left handed 
% $$$ ; rotation around norm from that orientation.
% $$$ ;
% $$$ ; Finally, there is a conversion from Dicom [rl,ap,fh] to Nifti [lr,pa,fh] (fh= inferior to superior)
% $$$ ; 
% $$$ ; The normal vector is from Siemens hdr, in [rl,ap,fh] coordinates
    if all(size(normal)==[3,3])
        % Input is a rotation matrix
        rp=normal.'*[-1,0,0;0,-1,0;0,0,1];
    elseif size(normal,1)==9
        rp=reshape(normal(:,1),[3,3]).'*[-1,0,0;0,-1,0;0,0,1];
    else
        % Calculate rotation matrix
        if nargin<2
            prot=0;
        else
            prot=rot_inplane(1);
        end        
        % make sure that the input is normalized
        snor=normal(:)/total(normal.^2)^0.5;
        rp=gen_coordinate(snor,prot).'*[-1,0,0;0,-1,0;0,0,1];
    end
    %% Calculate quaternion
    % compute the determinant
    zd=(rp(1,1)*rp(2,2)*rp(3,3))-(rp(1,1)*rp(2,3)*rp(3,2))-(rp(1,2)*rp(2,1)*rp(3,3))+...
       (rp(1,2)*rp(2,3)*rp(3,1))+(rp(1,3)*rp(2,1)*rp(3,2))-(rp(1,3)*rp(2,2)*rp(3,1));
    if (zd <= 0)
        qfac=-1;
        rp(3,:)=-rp(3,:);
    else
        qfac=1;
    end
    % compute the quaternion values
    % see https://nifti.nimh.nih.gov/pub/dist/src/niftilib/nifti1_io.c - function nifti_mat44_to_quatern()
    % NOTE: the matrix is transposed compared to the example!
    quat=zeros(4,1);
    quat(1)=rp(1,1)+rp(2,2)+rp(3,3)+1;
    if quat(1)>1
        quat(1)=0.5*quat(1)^0.5;
        quat(2)=0.25*(rp(2,3)-rp(3,2))/quat(1);
        quat(3)=0.25*(rp(3,1)-rp(1,3))/quat(1);
        quat(4)=0.25*(rp(1,2)-rp(2,1))/quat(1);
    else
        xd=1.0+rp(1,1)-(rp(2,2)+rp(3,3));
        yd=1.0+rp(2,2)-(rp(1,1)+rp(3,3));
        zd=1.0+rp(3,3)-(rp(1,1)+rp(2,2));
        if xd>1
            quat(2)=0.5*xd^0.5;
            quat(1)=0.25*(rp(2,3)-rp(3,2))/quat(2);
            quat(3)=0.25*(rp(2,1)+rp(1,2))/quat(2);
            quat(4)=0.25*(rp(3,1)+rp(1,3))/quat(2);
        elseif yd>1
            quat(3)=0.5*yd^0.5;
            quat(1)=0.25*(rp(3,1)-rp(1,3))/quat(3);
            quat(2)=0.25*(rp(2,1)+rp(1,2))/quat(3);
            quat(4)=0.25*(rp(3,2)+rp(2,3))/quat(3);
        else
            quat(4)=0.5*zd^0.5;
            quat(1)=0.25*(rp(1,2)-rp(2,1))/quat(4);
            quat(2)=0.25*(rp(3,1)+rp(1,3))/quat(4);
            quat(3)=0.25*(rp(3,2)+rp(2,3))/quat(4);
        end
        if quat(1)<0
            quat(1)=-quat(1);
            quat(2)=-quat(2);
            quat(3)=-quat(3);
            quat(4)=-quat(4);
        end
    end
    % re-compute the matrix from the quaternion values to allow a consistency check
    matrix=quaternion_to_rotmat(quat);
    drp=rp-matrix;
    if max(abs(drp(:)))>0.0001
        error('*** quaternion contains errors ***');
    end
end