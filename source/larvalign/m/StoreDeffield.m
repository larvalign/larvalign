function StoreDeffield( rootpath, deffieldPN, scanID, outputDir, ext, LogFileID)
%%
%% Warping of channel images
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-10-17
%%
try
% dirs & exe
warning('off','MATLAB:MKDIR:DirectoryExists');
exeDir = [rootpath '\resources\exe\'];
c3d = ['"' exeDir 'c3d.exe" '];

% Store deformation field
tic
logstr = [datestr(datetime) sprintf(' -- Storing deformation field...')];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);      
mkdir([outputDir 'DeformationFields'])
[status,cmdout] = system( [c3d ' -mcs ' '"' deffieldPN '\deformationField.mhd' '"' ' -omc  ' '"' outputDir 'DeformationFields\' scanID '.' ext '"']);  
assert(status==0, [datestr(datetime) sprintf(' -- Storing of deformation field failed.')] )
t=toc;
logstr = [datestr(datetime) sprintf(' -- Storing took: %g s' ,t)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);         

catch ME; 
    throwAsCaller(ME)
end

end
%%
%%
%%