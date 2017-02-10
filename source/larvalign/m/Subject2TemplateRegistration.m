function Subject2TemplateRegistration(rootpath, CPUGPU, scanID, ext, ChannelImgPFN, outputDir, doStoreDeffield, LogFileID)
%%
%% Subject2Template Registration -- Fully automatic intensity-based registration
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-12-12
%%
try 
    
% dirs & exe
warning('off','MATLAB:MKDIR:DirectoryExists');
exeDir = [rootpath '\resources\exe\'];
elxExe = ['"' exeDir 'elastix.exe" '];

% elastix config
exlPriority='idle';
parameterDir = [rootpath '\resources\elx_config\'];
switch CPUGPU
    case 'CPU'
    ParamNonlinearPFN = [parameterDir 'Nonlinear.txt']; 
    case 'GPU'
    ParamNonlinearPFN = [parameterDir 'Nonlinear_OpenCL.txt']; 
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


%% Registration of Subjects to Atlas   
tStart=tic;
logstr = [datestr(datetime) sprintf(' -- Performing fully-automatic intensity-based image registration of scan: %s' ,scanID)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);
warning('off','MATLAB:MKDIR:DirectoryExists');           
resultDir = [outputDir  'tmp\' scanID '\']; mkdir(resultDir);
resultStage1Dir = [resultDir '\DIR'];      
PreRegDir = [resultDir '\FlipRotPreReg'];   
ChannelImgPFN = Preprocess(rootpath, ChannelImgPFN, PreRegDir, LogFileID);
IF_NP_PFN   = [atlasNPDir atlasLabel];
IM_NP_PFN  =  ChannelImgPFN.NP;  

  
%% Preprocessing for pre-registration (large rotation and flip)
tic
logstr = [datestr(datetime) sprintf(' -- Linear registration of scan: %s' ,scanID)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);                  
GenerateTransformParameterFile(rootpath, CPUGPU, IM_NP_PFN, PreRegDir, LogFileID); 
TransformParamPreRegPFN = ZflipRotationRegistration(rootpath, CPUGPU, scanID, IM_NP_PFN, PreRegDir, '', '', LogFileID);   
t=toc;
logstr = [datestr(datetime) sprintf(' -- Linear registration took: %g s' ,t)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);    


%% Nonlinear registration (DIR)  
tic
mkdir(resultStage1Dir);     
fMask=[' -fMask ' '"' atlasNPDir atlasMaskN '"' ' '];  
shellElxDIR = [elxExe ' -out ' '"' resultStage1Dir '"' '  -f ' '"' IF_NP_PFN '"' ' -m ' '"' IM_NP_PFN '"' ' ' fMask...
                      ' -p ' '"' ParamNonlinearPFN '"' ' -t0 ' '"' TransformParamPreRegPFN '"' ' -priority ' exlPriority];                         
logstr = [datestr(datetime) sprintf(' -- Nonlinear registration...')];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);         
[statusDIR,cmdout] = system( shellElxDIR ); 
assert( (statusDIR==0 && exist([resultStage1Dir '\' transformLabel0],'file')),...
    [datestr(datetime) sprintf(' -- Nonlinear registration failed.\n') elxError(cmdout) ] )  
t=toc;
logstr = [datestr(datetime) sprintf(' -- Nonlinear registration took: %g s' ,t)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']); 

   

%% Computing composed dense deffield 
CombineTransformations( rootpath, resultStage1Dir, LogFileID)

%% Apply transformation to all channels  
WarpImages( rootpath, resultStage1Dir, scanID, ChannelImgPFN, outputDir, ext, LogFileID)

%% Registration finished
tElapsed = toc(tStart);
logstr = [datestr(datetime) sprintf(' -- Finished registration and warping of scan: %s in %g s.', scanID, tElapsed)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']); 

%% Registration Error Detection    
RegistrationErrorDetection(rootpath, resultStage1Dir, scanID, ext, resultDir, outputDir, LogFileID)

%% Save deformation field
if doStoreDeffield
    StoreDeffield( rootpath, resultStage1Dir, scanID, outputDir, ext, LogFileID)         
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