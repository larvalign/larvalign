function ChannelImgPFN = Preprocess(rootpath, ChannelImgPFN, PreRegDir, LogFileID)
%%
%% Preprocessing
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-10-21
%%
try
% dirs & exe
warning('off','MATLAB:MKDIR:DirectoryExists');
exeDir = [rootpath '\resources\exe\'];
c3d = ['"' exeDir 'c3d.exe" '];
scanID = ChannelImgPFN.ID;

NPDir = [PreRegDir '\NP\']; mkdir(NPDir);
NTDir = [PreRegDir '\NT\']; mkdir(NTDir);
GEDir = [PreRegDir '\GE\']; mkdir(GEDir);
ChannelImgPFN.WNP = ChannelImgPFN.NP;
ChannelImgPFN.WNT = ChannelImgPFN.NT;
ChannelImgPFN.WGE = ChannelImgPFN.GE;

logstr = [datestr(datetime) sprintf(' -- Preprocessing... ')];
fprintf(LogFileID,[logstr '\n']);
    

% Background correction 
[status,cmdout] = system([ c3d '"' ChannelImgPFN.NP '"  -info-full ']);                             
Ctmp=textscan(cmdout,'%s','Delimiter',{'  Mean Intensity     : '});
lowclip=num2str(ceil(cell2mat(textscan(Ctmp{1,1}{7,1},'%f'))));  
[status,cmdout] = system([  c3d '"' ChannelImgPFN.NP '"  -clip ' lowclip ' 255  -replace ' lowclip ' 0  -type uchar -compress -o "' NPDir scanID '.mhd"' ]);  
assert(status==0, 'Processing failure.')
ChannelImgPFN.NP = [NPDir scanID '.mhd'];

catch ME;
    try    
    logstr = [datestr(datetime) sprintf(' -- Processing failure.')];
    fprintf(LogFileID,[logstr '\n']); display(sprintf(logstr))       
    end   
    throwAsCaller(ME)
end

end
%%
%%
%%   