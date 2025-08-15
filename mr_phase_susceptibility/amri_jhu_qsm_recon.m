function amri_jhu_qsm_recon(im,para,qsm_file_char,path_out,varargin)
%% set up qsm parameters
    h=qsm_jhu_default;
    p=inputParser;
    unwrap_meth=[];
    bgrm_meth=[];
    qsm_solver=[];
    odd_even=0; % 1 odd, 2 even, array partial
    bet_f=0.02;
    % default bet_g is 0
    bet_g=0.0;
    fsl_dir=[];
    clear_path=0;
    b0=3;
    sharp_radius=10;
    template_echo=2;
    UnreliThreshold=2;
    unrelyphase1_thresh=0.2;
    unrelyphase2_thresh=0.5;
    echo_mask=[]; % index in selected echoes
    addParameter(p,'unwrap_meth',unwrap_meth,@isnumeric);
    addParameter(p,'bgrm_meth',bgrm_meth,@isnumeric);
    addParameter(p,'qsm_solver',qsm_solver,@isnumeric);
    addParameter(p,'odd_even',odd_even,@isnumeric);
    addParameter(p,'bet_f',bet_f,@isnumeric);
    addParameter(p,'bet_g',bet_g,@isnumeric);
    addParameter(p,'fsl_dir',fsl_dir,@ischar);
    addParameter(p,'clear_path',clear_path,@isnumeric);
    addParameter(p,'b0',b0,@isnumeric);
    addParameter(p,'sharp_radius',sharp_radius,@isnumeric);
    addParameter(p,'UnreliThreshold',UnreliThreshold,@isnumeric);
    addParameter(p,'unrelyphase1_thresh',unrelyphase1_thresh,@isnumeric);
    addParameter(p,'unrelyphase2_thresh',unrelyphase2_thresh,@isnumeric);
    addParameter(p,'echo_mask',echo_mask,@isnumeric);
    addParameter(p,'template_echo',template_echo,@isnumeric);
    p.parse(varargin{:});
    unwrap_meth=p.Results.unwrap_meth;
    bgrm_meth=p.Results.bgrm_meth;
    qsm_solver=p.Results.qsm_solver;
    odd_even=p.Results.odd_even;
    bet_f=p.Results.bet_f;
    bet_g=p.Results.bet_g;
    fsl_dir=p.Results.fsl_dir;
    clear_path=p.Results.clear_path;
    b0=p.Results.b0;
    sharp_radius=p.Results.sharp_radius;
    UnreliThreshold=p.Results.UnreliThreshold;
    unrelyphase1_thresh=p.Results.unrelyphase1_thresh;
    unrelyphase2_thresh=p.Results.unrelyphase2_thresh;
    echo_mask=p.Results.echo_mask;
    template_echo=p.Results.template_echo;
    % matlab .mat data
    if ischar(im) 
        [data_path,name,ext]=fileparts(im);
        if strcmp(ext,'.mat')
            load(im);
            im=im_recon;
            para=par.para;
        end
    end
    
    if ~isempty(unwrap_meth)
        h.VarUnwrappingMethod.Value=unwrap_meth;
        h.Params.UnwrappingMethod=h.VarUnwrappingMethod.Value;
    end
    if ~isempty(bgrm_meth)
        h.VarBgRemoval.Value=bgrm_meth;
        h.Params.BgRemoval=h.VarBgRemoval.Value;
    end
    if ~isempty(qsm_solver)
        h.VarQSMSolver.Value=qsm_solver;
        h.Params.QSMSolver=h.VarQSMSolver.Value;
    end
    h.Params.UnreliThreshold=UnreliThreshold;
    h.Params.unrelyPhase1_thresh=unrelyphase1_thresh;
    h.Params.unrelyPhase2_thresh=unrelyphase2_thresh;
    
    % change b0
    if isfield(para,'freq')
        b0=(para.freq)/42.58e6;
    end
    h.Params.b0=b0;
    % fsl bet
    h.Params.FSLThreshold=bet_f;
    h.Params.FSLThreshold_g=bet_g;
    if ~isempty(fsl_dir)
        h.Params.FSLFolder=fsl_dir;
    end
    
    h.Params.SHARPradius=sharp_radius;
    
    % for philips par/rec data
    if ischar(im)
        [data_path,name,ext]=fileparts(im);
        if strcmp(ext,'.par')
            GREdataAll  = readrec_V4_4(im, 1);
            Params      = ReadParFile(im, struct);     % extract basic scan parameters from .par file
            Params      = permuteParams(Params);
            Params.B0=b0;
            GREMag = (GREdataAll(:,:,:,:,:,1,1,1,1));
            GREPhase = (GREdataAll(:,:,:,:,:,1,1,1,2));
            % correct for odd even phase
            if numel(odd_even)>1 || odd_even==0
                data=GREMag.*exp(1i*GREPhase);
                ref_pha=dpOddEven_map(data,2);
                data(:,:,:,1:2:end)=data(:,:,:,1:2:end)./...
                    exp(1i*ref_pha/2);
                data(:,:,:,2:2:end)=data(:,:,:,2:2:end).*...
                    exp(1i*ref_pha/2);
                GREMag=abs(data);
                GREPhase=angle(data);
            end
            
            % echo number
            nte=size(GREMag,4);
        end
    else
        % echo number
        nte=para.nte_contr;
    end
    
    if isempty(echo_mask)
        echo_mask=nte;
    end
    h.Params.SaveEcho=echo_mask;
    
    h.Params.echoStart=1;
    h.Params.echoStep=1;
    if numel(odd_even)>1
        h.Params.echoEnd=numel(odd_even);
        qsm_file_char=[qsm_file_char,'_part'];
    elseif odd_even>0
% $$$         h.Params.echoStart=odd_even;
% $$$         h.Params.echoStep=2;
% $$$         h.Params.echoEnd=floor((nte-odd_even+2)/2)*2-2+odd_even;
        h.Params.echoEnd=floor((nte-odd_even+2)/2);
        if odd_even==1
            qsm_file_char=[qsm_file_char,'_odd'];
        else
            qsm_file_char=[qsm_file_char,'_even'];
        end
    else
        h.Params.echoEnd=nte;
        qsm_file_char=[qsm_file_char,'_both'];
    end
    h.Params.echoNums=h.Params.echoStart:h.Params.echoStep:h.Params.echoEnd;
    h.Params.gamma=42.58e6;
    % mask
    if ~isempty(para)
        h.Params.ErodeRadius=max(para.resr,para.resp);
    else
        h.Params.ErodeRadius=max(Params.voxSize(1:2));
    end
    h.Params.TemplateEcho=template_echo;
    % prep qsm input file
    if ~ischar(im) && ~isempty(para)
        if para.isgre
            odd_even_pha=~para.b_epi_positive;
        else
            odd_even_pha=false;
        end
        [GREMag,GREPhase,Params]=gen_jhu_qsm_data(im,para,odd_even_pha);
    end
    if numel(odd_even)>1
        GREMag=GREMag(:,:,:,odd_even(1):odd_even(end),:);
        GREPhase=GREPhase(:,:,:,odd_even(1):odd_even(end),:);
        Params.TEs=Params.TEs(odd_even(1):odd_even(end));
        Params.nEchoes=length(Params.TEs);
    elseif odd_even>0
        GREMag=GREMag(:,:,:,odd_even:2:end,:);
        GREPhase=GREPhase(:,:,:,odd_even:2:end,:);
        Params.TEs=Params.TEs(odd_even:2:end);
        Params.nEchoes=length(Params.TEs);
    end
    
    % save the data in the output folder
    if clear_path
        system(['rm ',fullfile(path_out,['qsm_',qsm_file_char,'*'])]);
    end
    qsm_file=['qsm_',qsm_file_char,'.mat'];
    save(fullfile(path_out,qsm_file),'GREMag','GREPhase','Params');
    tableData=prep_jhu_tabledata(path_out,qsm_file);
    save(fullfile(path_out,'DataTable.mat'),'tableData');
   
    h.DataListFile=fullfile(path_out,'DataTable.mat');
    h.textReadyLoad='Ready to be reconstructed';
    status=QSM_cluster([],[],h);
   
    % save qsm with the correct nifti header
    if ~isempty(para)
        qsm_m_file=['qsm_',qsm_file_char,...
                    '_chi_',h.Params.QSMSolverDict{h.Params.QSMSolver},...
                    '_'];
        fn_qsm=get_file_filter(path_out,[qsm_m_file,'*.mat'],0);
        load(fn_qsm);
        [p,n,e]=fileparts(fn_qsm);
        siem_to_nifti(fullfile(path_out,[n,'.nii.gz']),chi_res,para,1,1);
    end
% $$$     load(freq_m_file);
% $$$     siem_to_nifti(freq_file,freqMap,para,1,1);    
end
