function handles = LoadDataList_cluster(DataListFile, handles)
% 
%% Author: Xu Li
% Affiliation: Radiology @ JHU - Kirby Center
% Contact via xuli@mri.jhu.edu
% cluster version

% Open file
[PathName, FileName,FileExt] = fileparts(DataListFile);

% Something?
if(FileName ~= 0)
    S = load(fullfile(PathName, [FileName, FileExt]));
    if ~isfield(S, 'tableData')
        error('Data List not found');
    end
    
    % Get existing data table in the handles
    tableData   = handles.TableDatasets.Data;
    
    % Add new list to the tableData
    listnum = size(S.tableData, 1);
    for listii = 1:listnum        
        isNew = true;
        for c = 1:size(tableData,1)
            % Already in there
            if(strcmpi(tableData{c,1},S.tableData{listii, 1}))
                disp([S.tableData{listii, 1}, ' already listed']);
                isNew = false;
                break;
            end
        end

        % New?
        if(isNew)
            % New row to add
            newRow      =  { S.tableData{listii, 1}, handles.textReadyLoad };
            tableData   = [tableData; newRow];
        end        
    end
    
    % Update
    handles.TableDatasets.Data = tableData;
end