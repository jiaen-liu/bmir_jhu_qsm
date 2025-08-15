function [fo,bytes]=get_file_filter(path,filter,recursive)
    if nargin==1
        filter=path;
        [path,name,ext]=fileparts(filter);
        if isempty(path)
            path=pwd;
        end
        filter=[name,ext];
    end
    if nargin<3
        recursive=0;
    end
    bytes=0;
    pathc=pwd;
    cd(path);
    f=dir;
    nf=length(f);
    fo=[];
    if nf<1
        fo=[];
    end
    for i=1:nf
        if strcmp(f(i).name,'.') || ...
                strcmp(f(i).name,'..')
            continue;
        end
        if f(i).isdir && recursive
            [fo_tmp,bytes_tmp]=...
                get_file_filter(fullfile(pwd,...
                                         f(i).name),...
                                filter,...
                                recursive);
            if ischar(fo_tmp)
                fo=[fo;string(fo_tmp)];
            else
                fo=[fo;fo_tmp];
            end
            bytes=bytes+bytes_tmp;
        else
            match=regexp(f(i).name,...
                        regexptranslate('wildcard', filter));
            if ~isempty(match) && match==1
                fo=[fo;...
                    fullfile(pwd,string(f(i).name))];
                bytes=bytes+f(i).bytes;
            end
        end
    end
    if length(fo)==1
        fo=convertStringsToChars(fo);
    end
    cd(pathc);
end
