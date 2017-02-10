function CombineTransformations( rootpath, deffieldPN, LogFileID)
%%
%% Computation of combined transformation and dense deformation field
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-10-17
%%
try
% dirs & exe
warning('off','MATLAB:MKDIR:DirectoryExists');
exeDir = [rootpath '\resources\exe\'];
tfxExe = ['"' exeDir 'transformix.exe" '];

logstr = [datestr(datetime) sprintf(' -- Combining transformations and generating deformation field...')];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);
tic
shellTfx = [tfxExe ' -def all -out ' '"' deffieldPN '"' ' -tp ' '"' deffieldPN '\TransformParameters.0.txt' '"' ' -priority idle'];  
[status,cmdout] = system( shellTfx );
assert(status==0, [datestr(datetime) ' -- Combining transformations failed.\n' elxError(cmdout)] )    
t=toc;
logstr = [datestr(datetime) sprintf(' -- Generating deformation field took: %g s' ,t)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);     

catch ME; 
    throwAsCaller(ME)
end

end
%%
%%
%%