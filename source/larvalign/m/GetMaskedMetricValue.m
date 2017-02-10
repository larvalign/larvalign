function MaskedMetricValue = GetMaskedMetricValue(rootpath, AtlasTemplatePFN, I_R, I_Mask)
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-08-31
%%
exeDir = [rootpath '\resources\exe\'];
c3d = ['"' exeDir 'c3d.exe" '];
MaskedMetricValue(1) = nan;
MaskedMetricValue(2) = nan;

% MMI
[status,cmdout] = system([c3d '"' AtlasTemplatePFN '"' ' ' '"' I_R '"' ' ' '"' I_Mask '"' ' -popas fmask -mmi']);
assert(status==0 , [datestr(datetime) sprintf([' -- Processing failure.\n' cmdout])] )      
res=textscan(cmdout,'%s','Delimiter',{'='});
MaskedMetricValue(2) = str2double(res{1,1}{2,1});            
  

end
%%
%%
%%