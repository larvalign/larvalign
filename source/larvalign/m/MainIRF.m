%%
%% Image registration framework for registration of the larval CNS of Drosophila melanogaster
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-12-15
%%
%% 
function msg = MainIRF(varargin)

msg=[];
try 
    

%% Deployment root path
[pathstr0,name,ext] = fileparts(mfilename('fullpath'));
[rootpath,name,ext] = fileparts(pathstr0);
warning('off','MATLAB:MKDIR:DirectoryExists');
warning('off','all');

%% exe
c3d = ['"' rootpath '\resources\exe\c3d.exe" '];
FijiExe = ['"' rootpath '\resources\exe\Fiji\ImageJ-win64.exe" ' ];

%% Usage message
larvalignVersion='2017-Feb-08';
infoUsage=[...
    '\n'...
    'Version: ' larvalignVersion '\n'...
    '\n'...
    'Method: FullyAutomatic (default), SemiAutomatic. For details see draft of eLife article.\n'...
    '\n'...
    'Supported multi-channel input image formats: LSM (lsm), TIFF (tiff,tif).\n'...
    'If a multi-channel LSM/TIFF image is given, the channels will be split and converted for internal processing, and afterwards merged and stored in TIFF image format in the subfolder RegisteredScans/TIFF\n'...        
    'Usage: larvalign.exe  LSM_PFN value LSMchannelNP value LSMchannelNT value LSMchannelGE value OutputDir value OutputImgExt value CPUGPU value LandmarksTemplate value LandmarksSubjectPFN value\n'...            
    'LSM_PFN (mandatory): Full path-filename to the multi-channel image. LSMchannelNP (mandatory), LSMchannelNT, LSMchannelGE: channel position of the NP, NT, and GE image.\n'...                        
    '\n'...
    'Supported single-channel input/ouput image file formats: Analyze (hdr), GIPL (gipl,gipl.gz), MetaImage (mhd,mha), NIFTI (nii,nii.gz), Nrrd (nhdr,nrrd), VTK (vtk).\n'...   
    'Usage: larvalign.exe NPchannelImgPFN value NTchannelImgPFN value GEchannelImgPFN value OutputDir value OutputImgExt value CPUGPU value LandmarksTemplate value LandmarksSubjectPFN value\n'...            
    'NPchannelImgPFN (mandatory), NTchannelImgPFN (optional), GEchannelImgPFN (optional): Full path-filenames of the images of the NP, NT, and GE channel. NP: neuropil, NT: nerve tracts, GE: expression pattern.\n'...            
    '\n'...        
    'LandmarksSubjectPFN (mandatory for semi-automatic registration, ignored otherwise): Full path and filename to a text file in which the coordinates of the landmarks in the subject scan are stored.\n'...
    'LandmarksTemplatePFN (mandatory for semi-automatic registration, ignored otherwise): Full path and filename to a text file in which the coordinates of the landmarks in the template image are stored.\n'...     
    '\n'...  
    'OutputDir (mandatory): Data folder at which registration results will be stored.\n'...
    'OutputImgExt (default: input image format): Output image file extension.\n'...                   
    'CPUGPU (default: CPU): Using CPU or GPU (CUDA/openCL) for image registration.\n'...    
    'doStoreDeffield (optional): 0 (default, not stored) or 1.\n'...
    '\n'...  
    'The filename of the NP channel image is used as ID for the storage of the deformation field, registration quality assessment and the log file.\n'...
    'If the image of the NT and GE channel is given, then those are warped and stored; otherwise only the NP channel image is processed.\n'...
    '\n'...    
    'Results are stored in the following sub folders of OutputDir:\n'...
    '- RegisteredScans /NP, /NT, /GE, /TIFF\n'...
    '- DeformationFields\n'...
    '- QualityAssessment\n'...
    '- LogFiles\n\n'...
    '\n'... 
    'Help info: Shows this usage information.\n\n'];

msgRequired='';


%% Input argument parser
p = inputParser;
p.KeepUnmatched=false;

% Parameter parse definition
addOptional(p,'CPUGPU','CPU',@(x) any(validatestring(x,{'CPU','GPU'})));
addOptional(p,'doStoreDeffield','0');
addOptional(p,'OutputImgExt','');
addOptional(p,'NPchannelImgPFN','');
addOptional(p,'NTchannelImgPFN','');
addOptional(p,'GEchannelImgPFN','');
addOptional(p,'LandmarksTemplatePFN','');
addOptional(p,'LandmarksSubjectPFN','');
addOptional(p,'LSM_PFN','');
addOptional(p,'LSMchannelNP','',@(x) any(validatestring(x,{'1','2','3'})));
addOptional(p,'LSMchannelNT','',@(x) any(validatestring(x,{'1','2','3'})));
addOptional(p,'LSMchannelGE','',@(x) any(validatestring(x,{'1','2','3'})));
addOptional(p,'Method','FullyAutomatic',@(x) any(validatestring(x,{'FullyAutomatic','SemiAutomatic'})));
validationFcn = @(x) validateattributes(x,{'char'},{'nonempty'});
addParameter(p,'OutputDir','',validationFcn);
addParameter(p,'Help','')

msg=[];
try
parse(p,varargin{:});
catch ME
    msg='Invalid parameter usage. See "larvalign.exe Help info" for usage information.';
    return;
end



% required
[path,name,ext] = fileparts(strrep(p.Results.OutputDir,'/','\'));  
OutputDir = [fullfile(path,name,ext) '\'];
NPchannelImgPFN = strrep(p.Results.NPchannelImgPFN,'/','\');
InputImgExt=''; scanID='';
if ~isempty(NPchannelImgPFN)
    [path,name,ext] = fileparts(NPchannelImgPFN);
    InputImgExt = ext(2:end);
    scanID = name;
end
LSM_PFN = strrep(p.Results.LSM_PFN ,'/','\');
if ~isempty(LSM_PFN)
    doLSM = true;
    [path,name,ext] = fileparts(LSM_PFN);
    InputImgExt = ext(2:end);
    scanID = name;
else
    doLSM = false;
end
if strcmp(p.Results.Help,'info')
    display(sprintf(infoUsage))
    return
end
    

% optional
CPUGPU = p.Results.CPUGPU;
doStoreDeffield = logical(str2num(p.Results.doStoreDeffield));
OutputImgExt = p.Results.OutputImgExt; if isempty(OutputImgExt), OutputImgExt=InputImgExt; end
NTchannelImgPFN = strrep(p.Results.NTchannelImgPFN,'/','\');
GEchannelImgPFN = strrep(p.Results.GEchannelImgPFN,'/','\');
LandmarksTemplatePFN = strrep(p.Results.LandmarksTemplatePFN,'/','\');
LandmarksSubjectPFN = strrep(p.Results.LandmarksSubjectPFN,'/','\');
LSMchannelNP = p.Results.LSMchannelNP;
LSMchannelNT = p.Results.LSMchannelNT;
LSMchannelGE = p.Results.LSMchannelGE;
if isempty(LSMchannelNP), doLSM=false; end
Method = p.Results.Method;
if ~strcmp(Method,'SemiAutomatic')
    LandmarksTemplatePFN=[];
    LandmarksSubjectPFN=[];    
end


%% Sanity check
switch InputImgExt
    case 'tiff'
    case 'tif'    
    case 'lsm'
    case 'mhd'
    case 'mha'
    case 'hdr'
    case 'nii'
    case 'nii.gz'
    case 'gipl'
    case 'gipl.gz'
    case 'vtk'       
    case 'nhdr'
    case 'nrrd'
    otherwise
        msg=sprintf(['The input image file extension: ' OutputImgExt ' is not supported.\n']);
        display(sprintf(msg))        
        display(sprintf(msgRequired))
        return;
end    
    
switch OutputImgExt
    case 'tiff'
    case 'tif'    
    case 'lsm'
    case 'mhd'
    case 'mha'
    case 'hdr'
    case 'nii'
    case 'nii.gz'
    case 'gipl'
    case 'gipl.gz'
    case 'vtk'       
    case 'nhdr'
    case 'nrrd'
    otherwise
        msg=sprintf(['The output image file extension: ' OutputImgExt ' is not supported.\n'...
            'Supported ouput image file formats: TIFF (tiff,tif), Analyze (hdr), GIPL (gipl,gipl.gz), MetaImage (mhd,mha), NIFTI (nii,nii.gz), Nrrd (nhdr,nrrd), VTK (vtk).\n']);   
        display(sprintf(msg))        
        display(sprintf(msgRequired))
        return;
end                
allRequiredSet = ~isempty(OutputDir) && ~isempty(OutputImgExt) && ( ~isempty(NPchannelImgPFN) || doLSM );

if ( ~allRequiredSet )
    display(sprintf('\nNot all mandatory name-value pair arguments have been defined correctly.\n'))
    return;
end
resultDir = [OutputDir  'tmp\\' scanID ];



%% Log-file
warning('off','MATLAB:MKDIR:DirectoryExists');
mkdir([OutputDir 'LogFiles']);
LogFileID = fopen([OutputDir 'LogFiles\' scanID '.log'],'w');
compname = getenv('COMPUTERNAME');
convertBGB=1.048572612446164*10^6;
try, OS=''; [a OS] = system('ver'); catch ME; end
[user,sys]=memory;
try
    [a id] = system('wmic path win32_VideoController get name');
    GPU_ID = strtrim(id(20:end));      
catch ME
    GPU_ID='No GPU information found.';
end
[a cpu] = system('wmic cpu get name');
CPU_ID = strtrim(cpu(20:end));
RAM_total = sprintf('%g',[round(sys.PhysicalMemory.Total/convertBGB)]);
RAM_available = sprintf('%g',[round(sys.PhysicalMemory.Available/convertBGB)]);
logstr = [sprintf([datestr(datetime) '\n'])...
    sprintf('larvalign version: %s\n', larvalignVersion)...
    sprintf('Computer name: %s\n', compname)...
    sprintf('Operating system: %s\n', OS(2:end-1))...
    sprintf('CPU: %s\n', CPU_ID)...
    sprintf('Total RAM (MB): %s\n',RAM_total)...
    sprintf('Available RAM (MB): %s\n',RAM_available)...
    sprintf('GPU: %s\n', GPU_ID)];
display(sprintf(logstr)); fprintf(LogFileID,[logstr '\n']); 



%% tmp mhd dir
tmpDir=[OutputDir 'tmp\' scanID '\' ]; mkdir(tmpDir);
NPDir=[tmpDir 'NP\']; mkdir(NPDir);
NTDir=[tmpDir 'NT\']; mkdir(NTDir);
GEDir=[tmpDir 'GE\']; mkdir(GEDir);


%% Convert LSM to mhd
if doLSM
try
logstr = [datestr(datetime) sprintf(' -- Trying to convert LSM/TIFF image...')];
display(sprintf(logstr)),  fprintf(LogFileID,[logstr '\n']);

% LSMchannelNP
nbLSMchannels=1;
stringNP=[ ' selectWindow("C' LSMchannelNP '-' scanID '.' InputImgExt '"); '...
           ' run("MHD/MHA ...", "save=[' sep(NPDir) scanID  '.mhd]"); '];              
stringNT='';
stringGE='';
if ~isempty(LSMchannelNT)
    nbLSMchannels=nbLSMchannels+1; 
    stringNT=[ ' selectWindow("C' LSMchannelNT '-' scanID '.' InputImgExt '"); '...
               ' run("MHD/MHA ...", "save=[' sep(NTDir) scanID  '.mhd]"); '];    
end
if ~isempty(LSMchannelGE)
    nbLSMchannels=nbLSMchannels+1; 
    stringGE=[ ' selectWindow("C' LSMchannelGE '-' scanID '.' InputImgExt '"); '...
               ' run("MHD/MHA ...", "save=[' sep(GEDir) scanID  '.mhd]"); '];    
end

if strcmp(InputImgExt,'lsm')
fijiOpen1=[' run("LSM...", "open=[' sep(LSM_PFN) ']");']; 
end
if strcmp(InputImgExt,'tiff')||strcmp(InputImgExt,'tif')
fijiOpen1=[' run("ImageJ2...", "scijavaio=true");  open("' sep(LSM_PFN) '");'];
end
fijiproc1=[' run("Make Composite", "display=Composite"); run("Split Channels"); '...
    stringNP...
    stringNT...
    stringGE...
    ' run("Quit"); '];

stringBuffer = [ fijiOpen1 fijiproc1 ]; 
fileID = fopen([sep(tmpDir) scanID '_lsm2mhd.txt'],'w');
fprintf(fileID,'%s\n',stringBuffer);
fclose(fileID);    

[status,cmdout] = system([FijiExe ' --headless -macro "' sep(tmpDir) scanID '_lsm2mhd.txt"']); 
[status,cmdout] = system([ 'del  /Q  "' tmpDir scanID '_lsm2mhd.txt"']);  

catch ME    
    logstr = [datestr(datetime) sprintf(' -- Conversion of LSM/TIFF file failed.')];
    display(sprintf(logstr)),  fprintf(LogFileID,[logstr '\n']); 
    error(logstr);
end

end

%% Check if input files and images exist
logstr = [datestr(datetime) sprintf(' -- Valiate if input files exist...')];
display(sprintf(logstr)),  fprintf(LogFileID,[logstr '\n']); 
    
if doLSM 
    ChannelImgPFN.NP = [NPDir scanID '.mhd'];
    if ~isempty(LSMchannelNT)
        ChannelImgPFN.NT = [NTDir scanID '.mhd'];
    else
        ChannelImgPFN.NT='';
    end
    if ~isempty(LSMchannelGE)
        ChannelImgPFN.GE = [GEDir scanID '.mhd'];
    else
        ChannelImgPFN.GE='';
    end
else
    ChannelImgPFN.NP = NPchannelImgPFN;
    ChannelImgPFN.NT = NTchannelImgPFN;
    ChannelImgPFN.GE = GEchannelImgPFN;
end

ChannelImgPFN.ID = scanID;
ChannelImgPFN.ext = OutputImgExt;

msg=[];
if ~exist(ChannelImgPFN.NP,'file'), msgt=[sep(ChannelImgPFN.NP) '  does not exist.']; msg=[msg sprintf([msgt '\n'])]; end
if ~isempty(ChannelImgPFN.NT), if ~exist(ChannelImgPFN.NT,'file'), msgt=[sep(ChannelImgPFN.NT) '  does not exist.']; msg=[msg sprintf([msgt '\n'])]; end, end
if ~isempty(ChannelImgPFN.GE), if ~exist(ChannelImgPFN.GE,'file'), msgt=[sep(ChannelImgPFN.GE) '  does not exist.']; msg=[msg sprintf([msgt '\n'])]; end, end
if ~isempty(LandmarksSubjectPFN), if ~exist(LandmarksSubjectPFN,'file'), msgt=[sep(LandmarksSubjectPFN) '  does not exist.']; msg=[msg sprintf([msgt '\n'])]; end, end
if ~isempty(LandmarksTemplatePFN), if ~exist(LandmarksTemplatePFN,'file'), msgt=[sep(LandmarksTemplatePFN) '  does not exist.']; msg=[msg sprintf([msgt '\n'])]; end, end
if ~isempty(msg)
    logstr = [datestr(datetime) sprintf(sep(msg))];
    display(sprintf(sep(logstr))),  fprintf(LogFileID,[sep(logstr) '\n']);    
    return; 
end
if strcmp(Method,'SemiAutomatic')
if ( isempty(LandmarksSubjectPFN)~=isempty(LandmarksTemplatePFN) )
    msg=' -- Only one landmark text file is defined. For landmark-based registration corresponding landmark coordinates of the neuropil template image and the subject image must be provided.';
end    
end
if ~isempty(msg)
    logstr = [datestr(datetime) sprintf(sep(msg))];
    display(sprintf(sep(logstr))),  fprintf(LogFileID,[sep(logstr) '\n']); 
    return; 
end



%% Set parameters
logstr = [datestr(datetime) sprintf(' -- Set parameters:')];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);

if strcmp(OutputImgExt,'lsm'), OutputImgExt='tiff'; end

stringbuffer=[];
stringbuffer = [ stringbuffer sprintf( ['Method: ' Method '\n'] ) ]; 
stringbuffer = [ stringbuffer sprintf( ['CPUGPU: ' CPUGPU '\n'] ) ]; 
stringbuffer = [ stringbuffer sprintf( ['OutputDir: ' sep(OutputDir) '\n'] ) ]; 
stringbuffer = [ stringbuffer sprintf( ['Output image file extension: ' OutputImgExt '\n'] ) ]; 
stringbuffer = [ stringbuffer sprintf( ['NPchannelImgPFN: ' sep(ChannelImgPFN.NP) '\n'] ) ]; 
stringbuffer = [ stringbuffer sprintf( ['NTchannelImgPFN: ' sep(ChannelImgPFN.NT) '\n'] ) ]; 
stringbuffer = [ stringbuffer sprintf( ['GEchannelImgPFN: ' sep(ChannelImgPFN.GE) '\n'] ) ]; 
stringbuffer = [ stringbuffer sprintf( ['ScanID: ' scanID '\n'] ) ]; 
if doStoreDeffield, stringbuffer = [ stringbuffer sprintf( ['doStoreDeffield: true\n'] ) ];  else stringbuffer = [ stringbuffer sprintf( ['doStoreDeffield: false\n'] ) ];  end
stringbuffer = [ stringbuffer sprintf( ['LandmarksSubjectPFN: ' sep(LandmarksSubjectPFN) '\n'] ) ]; 
stringbuffer = [ stringbuffer sprintf( ['LandmarksTemplatePFN: ' sep(LandmarksTemplatePFN) '\n'] ) ]; 
fprintf(LogFileID, sep(stringbuffer) );
display( sprintf(sep(stringbuffer)) )


%% Validate that input files and images can be read
logstr = [datestr(datetime) sprintf(' -- Validate if input files can be read...')];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']); 
% Input images
msg=[];
status1=0;status2=0;status3=0;
[status1,cmdout1] = system([ c3d '"' ChannelImgPFN.NP '" -info ']);
if status1~=0, 
    msgt=['Cannot read file: ' sep(ChannelImgPFN.NP)]; msg=[msg sprintf([msgt '\n'])];
else
    msg=[msg sprintf([sep(ChannelImgPFN.NP) ':\n' cmdout1(10:end-1) ])];
end
if ~isempty(ChannelImgPFN.NT),     
    [status2,cmdout2] = system([ c3d  '"' ChannelImgPFN.NT '" -info ']);
    if status2~=0,
        msgt=['Cannot read file: ' sep(ChannelImgPFN.NT)]; msg=[msg sprintf([msgt '\n'])]; 
    else
       msg=[msg sprintf([sep(ChannelImgPFN.NT) ':\n' cmdout2(10:end-1) ])];
    end
end
if ~isempty(ChannelImgPFN.GE), 
    [status3,cmdout3] = system([ c3d  '"' ChannelImgPFN.GE '" -info ']);   
    if status3~=0, 
        msgt=['Cannot read file: ' sep(ChannelImgPFN.GE)]; msg=[msg sprintf([msgt '\n'])]; 
    else
        msg=[msg sprintf([sep(ChannelImgPFN.GE) ':\n' cmdout3(10:end-1) ])]; 
    end
end
display(sprintf(sep(msg))), fprintf(LogFileID,[sep(msg) '\n']);
if ( status1~=0 || status2~=0 || status3~=0 ), return; end




%% Convert landmark.points file from xml to elastix txt
if strcmp(Method,'SemiAutomatic')
try
logstr = [datestr(datetime) sprintf(' -- Converting landmark point files...')];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);
[path,name,LMText] = fileparts(LandmarksTemplatePFN);
[path,name,LMSext] = fileparts(LandmarksSubjectPFN);
if strcmp(LMText,'.points') && strcmp(LMSext,'.points')
tmp = Fiji_XMLread( strrep(LandmarksTemplatePFN, '/', '\') ); 
landmarkData.Template.XML = tmp(2).Children;    
for i = 1:size(landmarkData.Template.XML,2)
    if strcmp(tmp(2).Children(i).Attributes(2).Value,'false')
        landmarkData.Subject.label{i,1} = ' '; continue, end     
    landmarkData.Template.coord(i,1) = str2num( tmp(2).Children(i).Attributes(3).Value );
    landmarkData.Template.coord(i,2) = str2num( tmp(2).Children(i).Attributes(4).Value );
    landmarkData.Template.coord(i,3) = str2num( tmp(2).Children(i).Attributes(5).Value );
    landmarkData.Template.label{i,1} = landmarkData.Template.XML(i).Attributes(1).Value;
    landmarkData.Template.ID=scanID;
end
tmp = Fiji_XMLread( strrep(LandmarksSubjectPFN, '/', '\') ); 
landmarkData.Subject.XML = tmp(2).Children;    
for i = 1:size(landmarkData.Subject.XML,2)
    if strcmp(tmp(2).Children(i).Attributes(2).Value,'false')
        landmarkData.Subject.label{i,1} = ' '; continue, end     
    landmarkData.Subject.coord(i,1) = str2num( tmp(2).Children(i).Attributes(3).Value );
    landmarkData.Subject.coord(i,2) = str2num( tmp(2).Children(i).Attributes(4).Value );
    landmarkData.Subject.coord(i,3) = str2num( tmp(2).Children(i).Attributes(5).Value );
    landmarkData.Subject.label{i,1} = landmarkData.Subject.XML(i).Attributes(1).Value;
    landmarkData.Subject.ID=scanID;
end

% Selecting landmarks which are defined in both files
[C,ia,ib] = intersect(landmarkData.Subject.label, landmarkData.Template.label);
Template.coords = landmarkData.Template.coord(ib,:);
Subject.coords = landmarkData.Subject.coord(ia,:);
Template.size=size(Template.coords,1);
fid = fopen([tmpDir 'TemplateCoords.txt'],'w');
fprintf(fid,'point\n');
fprintf(fid,'%g\n',Template.size);
fprintf(fid,'%g %g %g\n',Template.coords');
fclose(fid);
Subject.size=size(Subject.coords,1);
fid = fopen([tmpDir 'SubjectCoords.txt'],'w');
fprintf(fid,'point\n');
fprintf(fid,'%g\n',Subject.size);
fprintf(fid,'%g %g %g\n',Subject.coords');
fclose(fid);
LandmarksTemplatePFN = [tmpDir 'TemplateCoords.txt'];
LandmarksSubjectPFN = [tmpDir 'SubjectCoords.txt'];

end
catch ME
    display(ME)
    logstr = [datestr(datetime) sprintf(' -- Conversion failed.')];
    display(sprintf(logstr)),  fprintf(LogFileID,[logstr '\n']);   
    error(logstr)   
end
end


%% Display landmark coordinates of landmark text files
msg=[];
if strcmp(Method,'SemiAutomatic')
fileID = fopen(LandmarksSubjectPFN); C = textscan(fileID, '%s','delimiter','\n'); fclose(fileID);
CC=C{1,1};
msg=['LandmarksSubjectPFN: ' sep(LandmarksSubjectPFN)  sprintf('\n')  sprintf('%s\n',CC{:}) ];
display(sprintf(msg)), fprintf(LogFileID,[msg '\n']);
fileID = fopen(LandmarksTemplatePFN); C = textscan(fileID, '%s','delimiter','\n'); fclose(fileID);
CC=C{1,1};
msg=['LandmarksTemplatePFN: ' sep(LandmarksTemplatePFN)  sprintf('\n')  sprintf('%s\n',CC{:}) ];
display(sprintf(msg)), fprintf(LogFileID,[msg '\n']);
end


%% Registration Method/Approach
if doLSM, OutImgExt='mhd';
else OutImgExt=OutputImgExt; end
switch Method
    case 'SemiAutomatic'
        Subject2TemplateRegistration_Semi(rootpath, CPUGPU, scanID, OutImgExt, ChannelImgPFN, OutputDir, LandmarksTemplatePFN, LandmarksSubjectPFN, doStoreDeffield, LogFileID);
    case 'FullyAutomatic'
        Subject2TemplateRegistration(rootpath, CPUGPU, scanID, OutImgExt, ChannelImgPFN, OutputDir, doStoreDeffield, LogFileID);     
    otherwise
end    


%% Convert mhd to tiff
if strcmp(OutputImgExt,'lsm') || strcmp(OutputImgExt,'tiff') || strcmp(OutputImgExt,'tif')
    
    logstr = [datestr(datetime) sprintf(' -- Composing and saving tiff multi-channel image.')];
    display(sprintf(logstr)),  fprintf(LogFileID,[logstr '\n']);    
    dir_fiji = sep([OutputDir 'RegisteredScans\']);
    outDir_fiji = [dir_fiji 'TIFF\\']; mkdir(outDir_fiji);    
    fijiOpen1=[' run("MHD/MHA...", "open=[' dir_fiji 'NP\\' scanID '.mhd]");'];
    tmp1=[' run("Save", "save=[' outDir_fiji 'np.tif]");'];      
    fijiOpen2='';fijiOpen3=''; tmp2='';tmp3='';merge2='';merge3='';    
    if ~isempty(ChannelImgPFN.NT) 
        fijiOpen2=[' run("MHD/MHA...", "open=[' dir_fiji 'NT\\' scanID '.mhd]");']; 
        tmp2=[' run("Save", "save=[' outDir_fiji 'nt.tif]");'];
        merge2=[' c' LSMchannelNT '=[nt.tif]'];
    end
    if ~isempty(ChannelImgPFN.GE)
        fijiOpen3=[' run("MHD/MHA...", "open=[' dir_fiji 'GE\\' scanID '.mhd]");']; 
        tmp3=[' run("Save", "save=[' outDir_fiji 'ge.tif]");'];
        merge3=[' c' LSMchannelGE '=[ge.tif]'];
    end             
    fijiMerge=[' run("Merge Channels...", "c' LSMchannelNP '=[np.tif]' merge2 merge3 '");'];
    fijiSaveTif=[' saveAs("ZIP", "' outDir_fiji  scanID '.tif.zip"); ']; 
    stringBuffer = [ fijiOpen1 tmp1 fijiOpen2 tmp2 fijiOpen3 tmp3 fijiMerge fijiSaveTif ' close(); run("Quit");'];    
    fileID = fopen([outDir_fiji scanID '_mhd2tif.txt'],'w');
    fprintf(fileID,'%s\n',stringBuffer);
    fclose(fileID);        
    [status,cmdout] = system([FijiExe '  --headless -macro "' outDir_fiji scanID '_mhd2tif.txt"']);
    delete( [outDir_fiji scanID '_mhd2tif.txt'], [outDir_fiji 'np.tif'], [outDir_fiji 'nt.tif'], [outDir_fiji 'ge.tif'] )    
    outNPDir = [OutputDir 'RegisteredScans\NP\'];
    outNTDir = [OutputDir 'RegisteredScans\NT\'];
    outGEDir = [OutputDir 'RegisteredScans\GE\'];    
    delete( [outNPDir scanID '.*'], [outNTDir scanID '.*'], [outGEDir scanID '.*'] );
    [status, message, messageid] = rmdir(outNPDir);
    [status, message, messageid] = rmdir(outNTDir);
    [status, message, messageid] = rmdir(outGEDir);    
    
end


%% Clean up
logstr = [datestr(datetime) sprintf(' -- Cleaning up...')];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']); 
[status, message, messageid] = rmdir(resultDir,'s'); 
[status, message, messageid] = rmdir(fileparts(resultDir));    
logstr = [datestr(datetime) sprintf(' -- Finished processing scan: %s.\n\n', scanID)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']); 
fclose(LogFileID);
fclose('all');
msg='0';



%%

catch ME;
    try 
    fprintf(LogFileID,[datestr(datetime) ' ---- ' ME.message '\n']);  
    logstr = [datestr(datetime) sprintf(' -- Processing failed.')];
    fprintf(LogFileID,[logstr '\n']);          
    end
    fclose('all');
    try   
    [status, message, messageid] = rmdir(resultDir,'s'); 
    [status, message, messageid] = rmdir(fileparts(resultDir)); 
    end  
    try
    display(ME)
    display(sprintf(logstr))    
    msg=logstr;
    end
end


end

function sepStr = sep( pathfilename  )
sepStr = strrep( pathfilename, '\','\\');
end
%%
%%
%%