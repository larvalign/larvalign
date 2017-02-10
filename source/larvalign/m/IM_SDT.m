function IM_SDT(rootpath, IM_PFN, PreRegDir, LogFileID)
%%
%% Warping of channel images
%%
%% Author: S.E.A. Muenzing, PhD
%% SEAM@2016-10-17
%%
try
% dirs & exe
warning('off','MATLAB:MKDIR:DirectoryExists');
exeDir = [rootpath '\resources\exe\'];
c3d = ['"' exeDir 'c3d.exe" '];
mkdir(PreRegDir)

% Computation of SDT of moving image mask  
IM_SDT_PFN = [PreRegDir '\Mask_SDT.mhd'];  
[status,cmdout] = system([ c3d '"' IM_PFN '"' ' -info-full ']);                               
Ctmp=textscan(cmdout,'%s','Delimiter',{'  Mean Intensity     : '});
meanIntensity = cell2mat(textscan(Ctmp{1,1}{7,1},'%f')); % estimation of background intensity
lowclip=num2str(ceil(meanIntensity)+5);  
[status,cmdout] = system([ c3d '"' IM_PFN '"'...
    ' -resample 50%' ...
    ' -clip ' lowclip ' 255  -replace ' lowclip ' 0 -binarize -erode 1 1x1x1 -dilate 1 1x1x1 -dilate 1 1x1x1 -dilate 1 1x1x1 -popas mask '...
    ' -push mask -sdt -type short -compress -o ' '"' IM_SDT_PFN '"' ]);
assert( status==0 )

catch ME;
    try    
    logstr = [datestr(datetime) sprintf(' -- Computation of SDT failed.')];
    fprintf(LogFileID,[logstr '\n']);    
    end   
    throwAsCaller(ME)
end

end
%%
%%
%%   