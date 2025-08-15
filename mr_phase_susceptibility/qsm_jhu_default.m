function handles=qsm_jhu_default
% Parameters setting template 
% -----------------------  Parameters set in GUI or script ------------------------
% parameters don't need to change
handles.Params.saveOutput           = 1;              % default 1 load existing intermediate result
handles.Params.LapPhaseCorrection   = 0;              % default
% Method Dictionary
handles.Params.UnwrappingMethodsDict    = {'Path', 'Laplacian', 'NonlinearFit + Path'}';
handles.Params.BgRemovalMethodsDict     = {'VSHARP', 'PDF', 'LBV+VSHARP', 'iRSHARP'}';
handles.Params.QSMSolverDict            = {'iLSQR','TKD','iTKD','MEDI','SFCR','nSFCR','FANSI','NDI','TFI'}';
% -----------parameters may need changes
handles.Params.thresh_tsvd          = 0.05;           % default, good trade-off
% -----------parameter input from GUI
% setup B0
handles.Params.B0                   = 3;              % Tesla
% Method selection
handles.VarUnwrappingMethod.Value   = 1;           % default, select according to Dict
handles.VarBgRemoval.Value          = 1;           % default, select according to Dict
handles.VarQSMSolver.Value          = 5;           % default, select according to Dict

% Phase pre-processing
handles.Params.UnwrappingMethod     = handles.VarUnwrappingMethod.Value;
handles.Params.phase2DprocFlag      = 0;           % default, edit, 0-1 

% Echo selection
handles.Params.echoStart            = 1;           % Edit for selecting starting echo
handles.Params.echoStep             = 1;           % default, can edit, 0 is single echo
handles.Params.echoEnd              = 2;           % Edit for selecting end echo
handles.Params.echoNums             = (handles.Params.echoStart):(handles.Params.echoStep):(handles.Params.echoEnd);

% for BrainMask
fsldir=getenv('FSL_DIR');
if isempty(fsldir)
    handles.Params.FSLFolder='';
else
    handles.Params.FSLFolder          = fullfile(fsldir,'bin/');   % in case needs to change
end
handles.Params.SaveEcho             = 1;              % default, edit, '1', or '[1,3]'  
handles.Params.FSLThreshold         = 0.02;           % default, edit, 0-1
handles.Params.ErodeRadius          = 0.5;            % default, edit, in mm
handles.Params.UnreliThreshold      = 2;              % default, edit, 0-2, threshold for detecting unreliable phase
handles.Params.unrelyPhase1_thresh  = 1e-6; % before BR, default 0.5
handles.Params.unrelyPhase2_thresh  = 1e-6; % after BR, default 0.5

% Echo Average
handles.Params.EchoAvg              = 1;              % default, edit, 0/1

% Background Removal
handles.Params.BgRemoval            = handles.VarBgRemoval.Value;
handles.Params.SHARPradius          = 10;              % default, edit, in mm

% QSM
handles.Params.QSMSolver            = handles.VarQSMSolver.Value;
handles.Params.R2starFlag           = 0;              % default, edit, 0/1
handles.Params.AutoRefFlag          = 0;              % default, edit, 0/1

% in other cases
handles.Params.nSFCRparams.nlM      = 0;              % default 1, edit 0/1
handles.Params.nSFCRparams.L1orL2   = 2;              % default 1, edit 1/2
handles.Params.nSFCRparams.TV       = 0;              % default 0, edit 0/1 

% % % --------------- Edit data filenames or data list
% % % --------------- Load in a test data
% PathName_1                          = 'D:\myWork\data\exampledata\001';
% FileName_1                          = '001.par';
% handles = OpenFiles_cluster(fullfile(PathName_1, FileName_1), handles);

% % --------------- Load in Processing list for batch processing
% handles.DataListFile                = fullfile('/data/user/jiaen_liu/data/20230508_1/result/DataTable.mat');
handles.DataListFile                = '';
handles.TableDatasets.Data = [];
handles.CurrentDataset = 0;
handles = LoadDataList_cluster(handles.DataListFile, handles);