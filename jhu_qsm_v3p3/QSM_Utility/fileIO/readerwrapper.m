function [GREMag, GREPhase, Params, handles] = readerwrapper(PathName, FileName, handles)
% function [GREMag, GREPhase, Params] = readerwrapper(PathName, FileName, handles)
%% Authors: Jiri van Bergen and Xu Li
% Affiliation: Radiology @ JHU - Kirby Center
% Contact via xuli@mri.jhu.edu
%
% readfilewrapper.m is the wrapper of readers for different file formats 
% created for QSM_Toolbox_v3
% updated 2019-07-09
% updated 2019-09-09, updated for Bruker data
% updated 2019-09-20, added coil combination for Siemens data
% updated 2021-01-01, updated .mat data
% updated 2021-03-11, updated for 2D Bruker data
% updated 2021-06-28, cluster version
% updated 2021-09-24, added mcpc-3d-s for multi-echo coil combination
% updated 2022-03-22, added option to load NIFTI hdr from .mat & DICOM (dicm2nii)
% updated 2023-02-02, for PAR/REC data without Phase Recon but with R/I
% updated 2023-05-07, added nifti support, nifti combined from dcm2niix
%                       output, see GRE_preparation_2nifti.m
% updated 2023-09-13, updated file requirements for nifti format

[~,FileBaseName,FileExt] = fileparts(FileName);

if(strcmpi(FileExt,'.par'))
    %% If GRE data in Rec Format
    GREdataAll  = readrec_V4_4([PathName FileName], 1);  

    % Parameters
    Params      = ReadParFile([PathName FileName], handles.Params);     % extract basic scan parameters from .par file
    Params      = permuteParams(Params);                                

    if size(GREdataAll, 9)  == 2
        GREMag = (GREdataAll(:,:,:,:,:,1,1,1,1));     % data type Mag, ncol, nrow, nslice,nechoes,ndynamics
        GREPhase = (GREdataAll(:,:,:,:,:,1,1,1,2));   % data type Phase same 5D array

    elseif size(GREdataAll, 9) > 2
        GREMag = (GREdataAll(:,:,:,:,:,1,1,1,1)); 
        GREReal = GREdataAll(:,:,:,:,:,1,1,1,2);
        GREImag = GREdataAll(:,:,:,:,:,1,1,1,3);
        GREPhase = angle(GREReal + 1i*GREImag);
        clear GREReal GREImag
    else
        % no phase data
        error('No phase data found. Cannont do QSM.')
    end

    %% Slice orientation

    switch Params.sliceOri
        case 1
            %% TRANSVERSAL (Normal)
            % Do nothing
        case 3
            %% CORONAL
            % Not fully tested yet
        case 2
            % Not fully tested yet
        otherwise
            disp('error info in slice orientation')
    end

    Params.datatype     = 'ParRec';

elseif(sum(strcmpi(FileExt,{'.DIC';'.IMA';'.DICOM'; '.dcm'; '.1'; ''})) > 0) && ~(strcmpi(FileBaseName, 'method'))
    % check whether conventional/enhanced dicom
    disp('reading dicom info ...');
    dicomheader = dicominfo([PathName FileName]);
    disp('Done.');
 
    if ~isfield (dicomheader, 'PerFrameFunctionalGroupsSequence')
        %% conventional DICOM in PathName
        % data in 6D array, ncol, nrow, nslice, necho, ndyanmics, ncoil
        [GREPhase, GREMag, Params] = read_DICOM(PathName, handles.Params);
        GREMag = permute(GREMag, [2,1,3:length(size(GREMag))]);
        GREPhase = permute(GREPhase, [2,1,3:length(size(GREPhase))]);
        Params = permuteParams(Params);

    else
        %% enhanced DICOM
        disp('reading enhanced DICOM data, please wait ...')
        [GREdataAll, dicomheader] = dicomeread([PathName FileName]);
        disp('Done.')
        Params = readparamsfromdicom(dicomheader, handles.Params);    
        [Params.PathName, Params.FileBaseName, ~] = fileparts([PathName, FileName]);

        ndimsGREdataAll = ndims(GREdataAll);
        if ndimsGREdataAll == 5
            GREdataAll = permute(GREdataAll ,[1,2,3,5,4]);  % 3D x imagetype x echoes
            GREMag = GREdataAll(:,:,:,:,1);     % if multi-echo, Magnitude
            GREPhase = GREdataAll(:,:,:,:,2);   % Phase
        elseif ndimsGREdataAll == 4
            GREMag = GREdataAll(:,:,:,1);       
            GREPhase = GREdataAll(:,:,:,2);
        end

    end
    
    if ~isfield(handles.Params, 'cluster')  % GUI only
        set(handles.VarB0,'String', Params.B0);    
    end

    if Params.coilNum > 1       % if uncombined data, do coil combination
        disp('Doing coil combination.')
        % Coil combination for PHASE VRC
        if Params.nEchoes > 1 
            % GREPhase = mcpcVRC(GREMag, GREPhase, Params);         % VRC
            [GREPhase, GREMag] = mcpc3Ds(GREMag, GREPhase, Params); % MCPC-3D-S
        else
            GREPhase = mcpcVRC(GREMag, GREPhase, Params);    % Multi-channel phase combination, VRC
        end
        % Coil combination MAGNITUDE, sum of square
        GREMag = sqrt(sum(GREMag.^2, 6));                % over coil dim;
    end
    
    Params.datatype     = 'DICOM'; 

    saveDICOM2mat = 1;
    if saveDICOM2mat == 1
        save([Params.FileBaseName, '.mat'], 'GREMag', 'GREPhase', 'Params', '-v7.3');
    end

elseif(strcmpi(FileBaseName, 'method'))
    %% Bruker files, assumes GREMag & GREPhase are in pdata/1 & pdata/2
    % still need to test on multi-echo, multi-channel data
    Params = handles.Params;
    PathName_Mag = fullfile(PathName, 'pdata', '1');
    PathName_Phase = fullfile(PathName, 'pdata', '2');
    
    % Updated read_2dseq.m, modified from Chern-Chyi (Cecil) Yen @ CMS/LFMI/NINDS/NIH
    %   dim1 dim2 dim3 Echo Slice Cycle Repetition Channel Complex
    [GREMag, hdr_Mag] = read_2dseq(PathName_Mag); 
    [GREPhase, hdr_Phase] = read_2dseq(PathName_Phase);
    
    GREMag = cast(GREMag, 'single');
    GREPhase = -1.0*cast(GREPhase, 'single');  % sign may flip with new data
    
    Params.sizeVol = hdr_Mag.size(:)';
    % in case GREMag and GREPhase had different recon
    if sum(hdr_Mag.size ~= hdr_Phase.size) > 0 || sum(hdr_Mag.VisuCoreOrientation(:) ~= hdr_Phase.VisuCoreOrientation(:)) > 0
        GREPhase = permute(GREPhase, [2,1,3:length(size(GREPhase))]);  % slice number should match
    end

    Params.voxSize = hdr_Mag.dim(:)';
    Params.fov = Params.sizeVol(1:3).*Params.voxSize;
    Params.coilNum = hdr_Mag.NumInputChan;
    
    Params.TR = hdr_Mag.RepetitionTime;
    Params.nEchoes = hdr_Mag.NEchoes;
    Params.TEs = hdr_Mag.TEs;
    Params.nDynamics = hdr_Mag.NRepetitions;
    Params.VisuCoreDim = hdr_Mag.VisuCoreDim;   % 2D vs 3D
    
    if contains(hdr_Mag.SliceOrient, 'axial', 'IgnoreCase', true)
        Params.sliceOri = 1;
    elseif contains(hdr_Mag.SliceOrient, 'sag', 'IgnoreCase', true)
        Params.sliceOri = 2;
    elseif contains(hdr_Mag.SliceOrient, 'coronal', 'IgnoreCase', true)
        Params.sliceOri = 3;
    else
        disp('unknown slice orientation.')
    end
    
    % test 2021-08-24 according to BU Bruker data
    GREPhase = -1.0*GREPhase;
    % Params.sliceOri = 1;

    Params.TAng         = (hdr_Mag.VisuCoreOrientation)';  % still need test, initial test 2022, see also conv_kernel_rot_c0.m
    Params.datatype     = '2dseq'; 

    Params.PathName = PathName;    
    parentFolders = textscan(PathName, '%s', 'delimiter', filesep);
    parentFolders = parentFolders{1};
    Params.FileBaseName = parentFolders{length(parentFolders)-1};

    if ~isfield(handles.Params, 'cluster')  % GUI only
        % Update labels
        set(handles.TextFileName, 'String', Params.FileBaseName);
        set(handles.VarB0, 'String', '11.7'); % GUESS
    end
    
    % coil combination
    if Params.coilNum > 1       % if uncombined data, do coil combination
        disp('Doing coil combination.')
        % Coil combination for PHASE
        if Params.nEchoes > 1  
            [GREPhase, GREMag] = mcpc3Ds(GREMag, GREPhase, Params);    % MCPC-3D-S
        else
            % single echo use VRC
            [GREPhase, GREMag] = mcpcVRC(GREMag, GREPhase, Params);    % Multi-channel phase combination, with mcpvcr
        end
        % Coil combination MAGNITUDE, sum of square
        GREMag = sqrt(sum(GREMag.^2, 6));                % over coil dim;
    end    
        
    GREMag = permute(GREMag, [2,1,3:length(size(GREMag))]);
    GREPhase = permute(GREPhase, [2,1,3:length(size(GREPhase))]);
    Params = permuteParams(Params);
    
elseif (strcmpi(FileExt,'.mat'))
    % matlab .mat file, need to have both GREMag, GREPhase, Params
    disp(['reading ', PathName, FileName, '...'])
    S = load([PathName FileName]);

    if ~isfield(handles.Params, 'cluster')  % GUI only
        if isfield(S.Params, 'B0')
            set(handles.VarB0,'String', S.Params.B0);     
        end
    end
    
    GREMag = S.GREMag;
    GREPhase = S.GREPhase;
    Params = handles.Params;

    Params.sizeVol = S.Params.sizeVol;
    Params.fov = S.Params.fov;
    Params.voxSize = S.Params.voxSize;

    Params.B0 = S.Params.B0;
    Params.TR = S.Params.TR;
    Params.nEchoes = S.Params.nEchoes;
    Params.TEs = S.Params.TEs;

    Params.TAng = S.Params.TAng;

    Params.PathName = PathName;
    Params.FileBaseName = FileBaseName;

    if isfield(S.Params, 'nDynamics')
        Params.nDynamics = S.Params.nDynamics;
    else
        Params.nDyanmics =  1;
    end

    if isfield(S.Params, 'sliceOri')
        Params.sliceOri = S.Params.sliceOri;
%         Params.ang = S.Params.ang;
%         Params.AngAP = S.Params.AngAP;
%         Params.AngFH = S.Params.AngFH;
%         Params.AngRL = S.Params.AngRL;            
    end

    if isfield(S.Params, 'Tsom')
        Params.TAnginv = S.Params.TAnginv;

        Params.Tpom = S.Params.Tpom;
        Params.Tpominv = S.Params.Tpominv;

        Params.Tsom = S.Params.Tsom;
        Params.Tsominv = S.Params.Tsominv;
    end
    
    if isfield(S.Params, 'SliceOriSave')
        Params.SliceOriSave = S.Params.SliceOriSave;
    end

    if isfield(S.Params, 'nifti_hdr')
        % check read_DICOM.m and read_DICOM.py
        Params.nifti_hdr = S.Params.nifti_hdr;
        Params.nifti_flp = S.Params.nifti_flp;
        Params.nifti_affine = S.Params.nifti_affine;        
        Params.nifti_flp_sli = S.Params.nifti_flp_sli;
    end

    if isfield(S.Params, 'datatype')
        Params.datatype = S.Params.datatype;
    end

elseif (strcmpi(FileExt,'.gz') || strcmpi(FileExt, '.nii'))
    
    % nifti file of magnitude/phase pair
    % read other Params from the correspoinding .mat file
    % which is extracted from json files, assume NIFTI is in default RAS system

    if contains(FileBaseName, '_GRE_mag')
        FileBaseName = extractBefore(FileBaseName, '_GRE_mag');
    elseif contains(FileBaseName, '_GRE_phase')
        FileBaseName = extractBefore(FileBaseName, '_GRE_phase');
    else
        error('Wrong naming convention.')
    end

    nii_mag = load_untouch_nii([PathName FileBaseName, '_GRE_mag.nii.gz']);
    nii_phase = load_untouch_nii([PathName FileBaseName, '_GRE_phase.nii.gz']);
    GREMag = permute(nii_mag.img, [2,1,3:ndims(nii_mag.img)]);
    GREPhase = permute(nii_phase.img, [2,1,3:ndims(nii_phase.img)]);

    S = load([PathName FileBaseName, '_header.mat']);      

    Params = handles.Params;            % copy other field in handles.Params first
    
    % copy fields
    if isfield(S, 'Params')
        fn_list = fieldnames(S.Params);
        for fn_idx = 1:length(fn_list)
            Params.(fn_list{fn_idx}) = S.Params.(fn_list{fn_idx});
        end
%         Params.nifti_hdr = S.Params.nifti_hdr;
%         Params.TEs       = S.Params.TEs;
%         Params.B0        = S.Params.B0;
%         Params.TR        = S.Params.TR;
%         Params.sizeVol   = S.Params.sizeVol;
%         Params.voxSize   = S.Params.voxSize;
%         Params.fov       = S.Params.fov;
%         Params.nDynamics = S.Params.nDynamics;

    else
        error('header file missing Params variable.')
    end

    % permute
    Params = permuteParams(Params);

    Params.PathName = PathName;
    Params.FileBaseName = FileBaseName;

    if ~isfield(handles.Params, 'cluster')  % GUI only
        if isfield(Params, 'B0')
            set(handles.VarB0,'String', Params.B0);     
        end
    end

else
    error('Sorry, we can not open this type of file...');
end