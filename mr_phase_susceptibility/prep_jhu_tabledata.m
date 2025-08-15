function tableData=prep_jhu_tabledata(path,fname,exclude)
   f=get_file_filter(path,fname,1);
   if ischar(f)
       f=convertCharsToStrings(f);
   end
   n=length(f);
   tableData=cell(n,2);
   for i=1:n
       tableData{i,1}=convertStringsToChars(f(i));
       tableData{i,2}='Ready';
   end
   if nargin<3
       exclude=[];
   end
   if ~isempty(exclude)
       tableData(exclude,:)=[];
   end
end