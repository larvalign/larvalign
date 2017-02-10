function GenerateTransformParameterFile(rootpath, CPUGPU, IM_PFN, PreRegDir, LogFileID)
%%
%% Generate TransformParameters files for pre-registration to map scans flipped in Z-dimension
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-09-05
%%
try
%% dirs & init
warning('off','MATLAB:MKDIR:DirectoryExists'); 
mkdir(PreRegDir)
exeDir = [rootpath '\resources\exe\'];
elxExe = ['"' exeDir 'elastix.exe" '];
c3d = ['"' exeDir 'c3d.exe" '];
atlasNPDir = [rootpath '\resources\Templates\Neuropil\'];
atlasLabel='AtlasImgMedian.mhd';
templateImgPFN = [atlasNPDir atlasLabel];
exlPriority='idle';

% parameter files
parameterDir = [rootpath '\resources\elx_config\'];
PreRegTemplateZflipPFN=[ parameterDir 'PreRigidTransformParameters_Zflip.txt'];


%% Logfile
logstr = [datestr(datetime) sprintf(' -- Preparing initial transformation...')];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);
    
    
%% Transform to template dimension by center of image
IF = templateImgPFN;
switch CPUGPU
    case 'CPU'
        PreRegCompPFN = [parameterDir 'PreReg_CompSDT.txt']; 
    case 'GPU'
        PreRegCompPFN = [parameterDir 'PreReg_CompSDT_OpenCL.txt'];
end     
elxExeShell= [elxExe ' -f ' '"' IF '"' ' -m ' '"' IM_PFN '"' ' '   ' -out ' '"' PreRegDir '"' ' -p ' '"' PreRegCompPFN '"'  ' -priority ' exlPriority]; 
[status,cmdout] = system( elxExeShell); 
assert( status==0 )
IMCenter_PFN = [PreRegDir '\result.0.mhd'];


%% read PreRegTemplateZ & PreRegTemplateZflip
fileID = fopen(PreRegTemplateZflipPFN);
PreRegTemplateZflip = textscan(fileID,'%s','Delimiter',{'\r\n'});
fclose(fileID);
InitialTransformParametersFileName = [PreRegDir '\TransformParameters.0.txt'];

%% Generate TransformParameters 
header=read_mhd_header( IMCenter_PFN );
assert( ~isempty(header), 'Error reading image file header.')
template=PreRegTemplateZflip{1,1};
idx=find(~cellfun(@isempty, strfind(template,'(InitialTransformParametersFileName')));
template{idx,1} = ['(InitialTransformParametersFileName "' InitialTransformParametersFileName '")'];

% Rotation in x-y plane
doRotZ=false;
idxT=find(~cellfun(@isempty, strfind(template,'(TransformParameters')));
try
[status,cmdout] = system([ c3d '"' IMCenter_PFN '"' ' -thresh 30 255 1 0 -centroid']);
centroidVox=cell2mat(textscan(cmdout,'CENTROID_VOX [%u, %u, %u]'));
if (header.Dimensions(2)-centroidVox(2)) < (header.Dimensions(2)/2) 
    doRotZ=true; 
    template{idxT,1} = ['(TransformParameters 0 3.14159 3.14159 0 0 0 )']; 
end
catch ME
    logstr = [datestr(datetime) sprintf(' -- Unexpected intensity distribution. Rotation analysis failed.')];
    display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);  
end

% calc center of rotation, i.e. image center
imgcenter=round( (header.Offset+(header.Dimensions .* header.PixelDimensions)) ./ 2);
idx=find(~cellfun(@isempty, strfind(template,'CenterOfRotationPoint')));
template{idx,1} = ['(CenterOfRotationPoint ' num2str(imgcenter) ')'];

% write to file
fileID = fopen( [PreRegDir '\TransformParameters_-Z.txt'],'w');
fprintf(fileID,'%s\n',template{:});
fclose(fileID);  

% TransformParameters_Z
if doRotZ
    template{idxT,1} = ['(TransformParameters 0 0 3.14159 0 0 0 )']; 
else
    template{idxT,1} = ['(TransformParameters 0 0 0 0 0 0 )']; 
end
fileID = fopen( [PreRegDir '\TransformParameters_Z.txt'],'w');
fprintf(fileID,'%s\n',template{:});
fclose(fileID);  

catch ME; 
    try    
    logstr = [datestr(datetime) sprintf(' -- Pre-registration initialization failed.')];
    fprintf(LogFileID,[logstr '\n']); 
    end               
    throwAsCaller(ME)
end

end
%%
%%
%%