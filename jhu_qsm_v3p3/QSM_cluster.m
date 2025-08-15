function [status] = QSM_cluster(varargin)
path0=pwd;
% this is the cluster version with no gui interaction
% status = QSM_cluster(varargin)
% Example call: 
%   ParamsSetFile = 'ParamsSetting_cluster.m';
%   LogFile = 'logd.txt';
%   QSM_cluster(ParamsSetFile, LogFile)

ParamsFile = 'ParamsSetting_cluster.m';
logfile = [];
par_struct=[];
if nargin>0 && ~isempty(varargin{1})
    ParamsFile = varargin{1};
end
if nargin>1
    logfile = varargin{2};
end
if nargin>2
    par_struct=varargin{3};
end
if isempty(logfile)
    logfile = fullfile(fileparts(mfilename('fullpath')), 'logd.txt');
    logtxt = 'Log to logd.txt';
else
    logtxt = ['Run parameters setting script:', strrep(ParamsFile, '\', '\\'), ' and log to ', strrep(logfile, '\', '\\')];
end
disp(logtxt);

% Add modules
FilePath = fileparts(mfilename('fullpath'));
addpath(FilePath);
addpath(genpath(fullfile(FilePath, 'QSM_Modules')));
addpath(genpath(fullfile(FilePath, 'QSM_NIFTI')));
addpath(genpath(fullfile(FilePath, 'QSM_Utility')));

% Start logging
writelog(logfile, [logtxt, '\n'], 'w');     % discard previous logs

% Use structure "handles" instead of graphic object handles
handles.Params.cluster = 1;       % flag the cluster version without GUI
handles.logfile = logfile;        % save logfile

% setting up constants
% The constants are defined by the parameter file, not needed here.
% Constants;

try
    if ~isempty(ParamsFile)
        run(ParamsFile);
    end
    if ~isempty(par_struct)
        params0=handles.Params;
        handles=pass_var_struct(handles,par_struct);
        handles = LoadDataList_cluster(handles.DataListFile, handles);
        params0=pass_var_struct(params0,par_struct.Params);
        handles.Params=params0;
    end
catch ME
    writelog(logfile, (ME.message))
    status = 1;
    cd(path0);
    return;
end
% Multi-step QSM processing including 1. PerformUnwrapping; 2.
% CreateBrainMask; 3. RemoveBackground; 4. CalculateQSM;
StartMultiProcess;

% Done
logtxt = 'QSM_script processing completed.';
disp(logtxt);
writelog(logfile, logtxt);
status = 0;
cd(path0);
