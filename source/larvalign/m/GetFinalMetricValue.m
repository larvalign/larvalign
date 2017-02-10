function FinalMetricValue = GetFinalMetricValue( elxLogPN )
%%
%% Author: S.E.A. Muenzing
%%
% Read elastix log-file:
try
fileID = fopen([elxLogPN '\elastix.log']);
tmp = textscan(fileID,'%s','Delimiter',{'\r\n'});
fclose(fileID);
idx=find(~cellfun(@isempty, strfind(tmp{1,1},'Final metric value  = ')));
if ~isempty(idx)
tmp2=tmp{1,1}{idx(end),1};
res=[]; res=textscan(tmp2,'%s','Delimiter',{'='});   
FinalMetricValue=str2double(res{1,1}{2,1});
else
    FinalMetricValue=0; % assume registration failed with exception in log file
end
catch ME
    FinalMetricValue=0;
end
    
