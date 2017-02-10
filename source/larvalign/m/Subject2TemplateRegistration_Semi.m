function Subject2TemplateRegistration_Semi(rootpath, CPUGPU, scanID, ext, ChannelImgPFN, outputDir, LandmarksTemplatePFN, LandmarksSubjectPFN, doStoreDeffield, LogFileID)
%%
%% Subject2Template Registration -- Semi-automatic landmark+intensity registration
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-08-30
%%
try 
    
% dirs & exe
warning('off','MATLAB:MKDIR:DirectoryExists');
exeDir = [rootpath '\resources\exe\'];
elxExe = ['"' exeDir 'elastix.exe" '];
resultDir = [outputDir  'tmp\' scanID '\']; mkdir(resultDir);


% elastix config
parameterDir = [rootpath '\resources\elx_config\'];
switch CPUGPU
    case 'CPU'
    SemiParamNonlinearPFN = [parameterDir 'NonlinearSemi.txt']; 
    case 'GPU'
    SemiParamNonlinearPFN = [parameterDir 'NonlinearSemi_OpenCL.txt']; 
    otherwise        
        logstr = [datestr(datetime) sprintf(' -- Invalid CPUGPU mode.')];
        display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);    
        error(logstr)
end
transformLabel0   = 'TransformParameters.0.txt';

% Images
atlasNPDir = [rootpath '\resources\Templates\Neuropil\'];
atlasLabel='AtlasImgMedian.mhd';
atlasMaskN='AtlasImgMedian_Mask.mhd';

% Landmark point correspondences 
fPoints = [' -fp ' '"' LandmarksTemplatePFN '"'];
mPoints = [' -mp ' '"' LandmarksSubjectPFN '"'];
    

%% Registration of subject to template    
tStart=tic;
logstr = [datestr(datetime) sprintf(' -- Performing landmark-intensity-based image registration of scan: %s' ,scanID)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);
warning('off','MATLAB:MKDIR:DirectoryExists');             
resultStage2Dir = [resultDir '\nonlinear'];          
PreRegDir = [resultDir '\FlipRotPreReg'];  
ChannelImgPFN = Preprocess(rootpath, ChannelImgPFN, PreRegDir, LogFileID);
IF_NP_PFN   = [atlasNPDir atlasLabel];
IM_NP_PFN  =  ChannelImgPFN.NP;

%% Preprocessing for pre-registration (large rotation and flip)      
tic
logstr = [datestr(datetime) sprintf(' -- Linear registration of scan: %s' ,scanID)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);               
GenerateTransformParameterFile(rootpath, CPUGPU, IM_NP_PFN, PreRegDir, LogFileID) 
TransformParamPreRegPFN = ZflipRotationRegistration(rootpath, CPUGPU, scanID, IM_NP_PFN, PreRegDir, LandmarksTemplatePFN, LandmarksSubjectPFN, LogFileID);
t=toc;   
logstr = [datestr(datetime) sprintf(' -- Linear registration took: %g s' ,t)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);      

%% Nonlinear registration  
tic
mkdir(resultStage2Dir);          
TransformParamLinearPFN=TransformParamPreRegPFN;
fMask=[' -fMask ' '"' atlasNPDir atlasMaskN '"' ' '];    
shellElxDIR = [elxExe ' -out ' '"' resultStage2Dir '"' '  -f ' '"' IF_NP_PFN '"' ' -m ' '"' IM_NP_PFN '"' ' ' fMask ' ' fPoints mPoints...
                      ' -p ' '"' SemiParamNonlinearPFN '"' ' -t0 ' '"' TransformParamLinearPFN '"' ' -priority idle'];  
logstr = [datestr(datetime) sprintf(' -- Nonlinear landmark-intensity-based registration...')];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);         
[statusDIR,cmdout] = system( shellElxDIR );    
if ( statusDIR~=0 || ~exist([resultStage2Dir '\' transformLabel0],'file') )
    logstr = [datestr(datetime) sprintf(' -- Nonlinear registration failed.\n') elxError(cmdout) ];
    display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);   
    error(logstr)
else   
t=toc;
logstr = [datestr(datetime) sprintf(' -- Nonlinear registration took: %g s' ,t)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']); 
end


%% Computing composed dense deffield 
CombineTransformations( rootpath, resultStage2Dir, LogFileID)

%% Apply transformation to all channels  
WarpImages( rootpath, resultStage2Dir, scanID, ChannelImgPFN, outputDir, ext, LogFileID)

%% Registration finished
tElapsed = toc(tStart);
logstr = [datestr(datetime) sprintf(' -- Finished registration and warping of scan: %s in %g s.', scanID, tElapsed)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']); 

%% Registration Error Detection    
RegistrationErrorDetection(rootpath, resultStage2Dir, scanID, ext, resultDir, outputDir, LogFileID)

%% Save deformation field
if doStoreDeffield
    StoreDeffield( rootpath, resultStage2Dir, scanID, outputDir, ext, LogFileID)         
end


catch ME; 
    try    
    logstr = [datestr(datetime) sprintf(' -- Registration failed.')];
    fprintf(LogFileID,[logstr '\n']);    
    end   
    throwAsCaller(ME)
end

end
%%
%%
%%