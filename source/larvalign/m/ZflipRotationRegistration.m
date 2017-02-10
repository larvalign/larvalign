function TransformParamPreRegPFN = ZflipRotationRegistration(rootpath, CPUGPU, scanID, IM_PFN, PreRegDir, LM_TemplatePFN, LM_SubjectPFN, LogFileID)
%%
%% Pre-registration to recover larger rotations
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-12-13
%%
try
%% dirs & filenames & exe
warning('off','MATLAB:MKDIR:DirectoryExists'); 

% reference images
atlasNPDir = [rootpath '\resources\Templates\Neuropil\'];
atlasLabel='AtlasImgMedian.mhd';
templateImg2FN='AtlasImgMedian25.mhd';
atlasSDTN='AtlasImgMedian_Mask_sdt.mhd';


% exe
exeDir = [rootpath '\resources\exe\'];
elxExe = ['"' exeDir 'elastix.exe" '];
exlPriority='idle';

% useLandmarks 
if ~isempty(LM_TemplatePFN) && ~isempty(LM_SubjectPFN)
    fPoints = [' -fp ' '"' LM_TemplatePFN '"'];
    mPoints = [' -mp ' '"' LM_SubjectPFN '"'];    
    useLandmarks=true;
else
    useLandmarks=false;
end

% parameter files
parameterDir = [rootpath '\resources\elx_config\'];
switch CPUGPU      
    case 'CPU'    
        PreRegSDTPFN = [parameterDir 'PreReg_SDT_MI.txt'];
        PreRegSDT2PFN = [parameterDir 'PreReg_SDT_MIF.txt'];
        PreRegIntensPFN = [parameterDir 'PreReg_Intensity_NC.txt'];
        PreRegIntens2PFN = [parameterDir 'PreReg_Intensity_NCF.txt']; 
        if useLandmarks
        PreRegSDTPFN = [parameterDir 'PreReg_SDT_MI_CoReg.txt'];
        PreRegIntensPFN = [parameterDir 'PreReg_Intensity_NC_CoReg.txt'];            
        end        
		
    case 'GPU'
		PreRegSDTPFN = [parameterDir 'PreReg_SDT_MI_OpenCL.txt'];
        % PreRegSDT2PFN = [parameterDir 'PreReg_SDT_MIF_OpenCL.txt'];  % GPU mem alloc failure possible
        PreRegSDT2PFN = [parameterDir 'PreReg_SDT_MIF.txt'];        
        PreRegIntensPFN = [parameterDir 'PreReg_Intensity_NC_OpenCL.txt'];
		% PreRegIntens2PFN = [parameterDir 'PreReg_Intensity_NCF_OpenCL.txt'];  % GPU mem alloc failure possible	
        PreRegIntens2PFN = [parameterDir 'PreReg_Intensity_NCF.txt'];
        if useLandmarks
        PreRegSDTPFN = [parameterDir 'PreReg_SDT_MI_CoReg_OpenCL.txt']; 
        PreRegIntensPFN = [parameterDir 'PreReg_Intensity_NC_CoReg_OpenCL.txt'];			
        end   
    otherwise        
        logstr = [datestr(datetime) sprintf(' -- Invalid CPUGPU mode.')];
        display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);    
        error(logstr)
end             


%% PreRegistration to find large rotations and flipping of scan
logstr = [datestr(datetime) sprintf(' -- Feature-based large rotation registration...')];
if useLandmarks, logstr = [datestr(datetime) sprintf(' -- Landmark-feature-based large rotation registration...')];end
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']); 

Orig_SDT_PN = [ PreRegDir '\Orig\SDT' ]; mkdir(Orig_SDT_PN);
Zflip_SDT_PN = [ PreRegDir '\Zflip\SDT' ]; mkdir(Zflip_SDT_PN);    
Orig_IntensSDT_PN = [ PreRegDir '\Orig\IntensSDT' ]; mkdir(Orig_IntensSDT_PN);
Zflip_IntensSDT_PN = [ PreRegDir '\Zflip\IntensSDT' ]; mkdir(Zflip_IntensSDT_PN);
Orig_Intens_PN = [ PreRegDir '\Orig\Intens' ]; mkdir(Orig_Intens_PN);
Zflip_Intens_PN = [ PreRegDir '\Zflip\Intens' ]; mkdir(Zflip_Intens_PN);  

% Compute SDT for feature-based registration
IM_SDT(rootpath, IM_PFN, PreRegDir, LogFileID);
  
% SDT registration for rotation recovering
IF = ['"' atlasNPDir atlasSDTN '"'];    
IM = ['"' PreRegDir '\Mask_sdt.mhd"'];    
TransformFileZflip=['"' PreRegDir  '\TransformParameters_-Z.txt"'];   
TransformFileZ=['"' PreRegDir  '\TransformParameters_Z.txt"']; 
elxExeShell_Orig_SDT= [elxExe ' -f ' IF ' -m ' IM ' -out ' '"' Orig_SDT_PN '"' ' -p ' '"' PreRegSDTPFN '"' ' -t0 ' TransformFileZ  ' -p '  '"'  PreRegSDT2PFN  '"'  ' -priority ' exlPriority]; 
elxExeShell_Zflip_SDT=[elxExe ' -f ' IF ' -m ' IM ' -out ' '"' Zflip_SDT_PN '"' ' -p ' '"' PreRegSDTPFN '"' ' -t0 ' TransformFileZflip  ' -p '  '"'  PreRegSDT2PFN  '"'  ' -priority ' exlPriority];
if useLandmarks                                              
elxExeShell_Orig_SDT= [elxExe ' -f ' IF ' -m ' IM ' ' fPoints mPoints  ' -out ' '"' Orig_SDT_PN '"' ' -p ' '"' PreRegSDTPFN '"' ' -t0 ' TransformFileZ ' -priority ' exlPriority]; 
elxExeShell_Zflip_SDT=[elxExe ' -f ' IF ' -m ' IM ' ' fPoints mPoints  ' -out ' '"' Zflip_SDT_PN '"' ' -p ' '"' PreRegSDTPFN '"' ' -t0 ' TransformFileZflip ' -priority ' exlPriority]; 
end

IF = [ '"' atlasNPDir templateImg2FN '"'];
IM = [ '"' IM_PFN '"'];         
TransformFileN = 'TransformParameters.0.txt';
elxExeShell_Orig_Intens= [elxExe ' -f ' IF  ' -m ' IM ' '   ' -out ' '"' Orig_IntensSDT_PN '"' ' -p ' '"' PreRegIntensPFN '"' ' -t0 ' '"' Orig_SDT_PN '\' TransformFileN '"' ' -p '  '"'  PreRegIntens2PFN  '"'  ' -priority ' exlPriority];  
elxExeShell_Zflip_Intens=[elxExe ' -f ' IF  ' -m ' IM ' '   ' -out ' Zflip_IntensSDT_PN ' -p ' '"' PreRegIntensPFN '"' ' -t0 ' '"' Zflip_SDT_PN '\' TransformFileN '"' ' -p '  '"'  PreRegIntens2PFN  '"'  ' -priority ' exlPriority];
if useLandmarks                                              
elxExeShell_Orig_Intens= [elxExe ' -f ' IF  ' -m ' IM ' ' fPoints mPoints  ' -out ' '"' Orig_IntensSDT_PN '"' ' -p ' '"' PreRegIntensPFN '"' ' -t0 ' '"' Orig_SDT_PN '\' TransformFileN '"' ' -priority ' exlPriority];  
elxExeShell_Zflip_Intens=[elxExe ' -f ' IF  ' -m ' IM ' ' fPoints mPoints  ' -out ' '"' Zflip_IntensSDT_PN '"' ' -p ' '"' PreRegIntensPFN '"' ' -t0 ' '"' Zflip_SDT_PN '\' TransformFileN '"' ' -priority ' exlPriority];    
end


% Register SDT
[status1,cmdout] = system( elxExeShell_Orig_SDT );  % orig
[status3,cmdout] = system( elxExeShell_Zflip_SDT ); % zflip
FinalMetricValue.origSDT = GetFinalMetricValue( Orig_SDT_PN );
FinalMetricValue.zflipSDT = GetFinalMetricValue( Zflip_SDT_PN );
    
% Register SDTIntens
% Intensity registration for refinement, based on SDT reg transformparameters
logstr = [datestr(datetime) sprintf(' -- Linear intensity-based registration...')];
if useLandmarks, logstr = [datestr(datetime) sprintf(' -- Linear landmark-intensity-based registration...')];end
fprintf(LogFileID,[logstr '\n']); display(sprintf(logstr))

status2=1;status4=1;
if (FinalMetricValue.origSDT <= FinalMetricValue.zflipSDT)
    [status2,cmdout] = system( elxExeShell_Orig_Intens );       
else
    [status4,cmdout] = system( elxExeShell_Zflip_Intens ); 
end 
FinalMetricValue.origSDTIntens = GetFinalMetricValue( Orig_IntensSDT_PN );
FinalMetricValue.zflipSDTIntens = GetFinalMetricValue( Zflip_IntensSDT_PN );
  
if FinalMetricValue.origSDT==0, status2=1;end % Mask/SDT failed
if FinalMetricValue.zflipSDT==0, status4=1;end % Mask/SDT failed
if FinalMetricValue.origSDTIntens>-0.40, status2=1;end % Reg likely failed
if FinalMetricValue.zflipSDTIntens>-0.40, status4=1;end % Reg likely failed


if ~useLandmarks
if (status2~=0 && status4~=0)  % run prereg w/o SDT
    IF = ['"' atlasNPDir atlasLabel '"'];
    IM = ['"' IM_PFN '"'];
    TransformFileZflip=['"' PreRegDir  '\TransformParameters_-Z.txt"'];   
    TransformFileZ=['"' PreRegDir  '\TransformParameters_Z.txt"'];       
    elxExeShell_Orig_Intens= [elxExe ' -f ' IF  ' -m ' IM ' '   ' -out ' '"' Orig_Intens_PN '"' ' -p ' '"' PreRegIntensPFN '"' ' -t0 ' TransformFileZ ' -p "'  PreRegIntens2PFN  '"' ' -priority ' exlPriority];  
    elxExeShell_Zflip_Intens=[elxExe ' -f ' IF  ' -m ' IM ' '   ' -out ' '"' Zflip_Intens_PN '"' ' -p ' '"' PreRegIntensPFN '"' ' -t0 ' TransformFileZflip ' -p "'  PreRegIntens2PFN  '"' ' -priority ' exlPriority];         
    [status22,cmdout] = system( elxExeShell_Orig_Intens );
    [status24,cmdout] = system( elxExeShell_Zflip_Intens );
    FinalMetricValue.origIntens = GetFinalMetricValue( Orig_Intens_PN );
    FinalMetricValue.zflipIntens = GetFinalMetricValue( Zflip_Intens_PN );       
end
end
delete([PreRegDir '\Mask_SDT.mhd'],[PreRegDir '\Mask_SDT.zraw'])



%% Final metric value of elastix 
FinalMetricValue.orig=FinalMetricValue.origSDTIntens;
FinalMetricValue.zflip=FinalMetricValue.zflipSDTIntens;
OrigTransformParamPreRegPFN = [PreRegDir '\Orig\IntensSDT\TransformParameters.0.txt'];
ZflipTransformParamPreRegPFN = [PreRegDir '\Zflip\IntensSDT\TransformParameters.0.txt'];

% Read elxExe log-file:
if ~useLandmarks
if (status2~=0 && status4~=0)       
    if (FinalMetricValue.origIntens<=FinalMetricValue.origSDTIntens) 
        FinalMetricValue.orig=FinalMetricValue.origIntens;
        OrigTransformParamPreRegPFN = [PreRegDir '\Orig\Intens\TransformParameters.0.txt'];
    else
        FinalMetricValue.orig=FinalMetricValue.origSDTIntens;
    end
    if (FinalMetricValue.zflipIntens<=FinalMetricValue.zflipSDTIntens)
        FinalMetricValue.zflip=FinalMetricValue.zflipIntens;
        ZflipTransformParamPreRegPFN = [PreRegDir '\Zflip\Intens\TransformParameters.0.txt'];
    else
        FinalMetricValue.zflip=FinalMetricValue.zflipSDTIntens;
    end
end
end

if useLandmarks
    FinalMetricValue.orig=FinalMetricValue.origSDT;
    FinalMetricValue.zflip=FinalMetricValue.zflipSDT;
end

if (FinalMetricValue.orig <= FinalMetricValue.zflip)
    TransformParamPreRegPFN = OrigTransformParamPreRegPFN;
else
    TransformParamPreRegPFN = ZflipTransformParamPreRegPFN;
end  


if (FinalMetricValue.orig==0 && FinalMetricValue.zflip==0)
    logstr = [datestr(datetime) sprintf(' -- Linear registration of scan: %s   failed.', scanID)];
    display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);
    error(logstr)                       
end
if ( ~useLandmarks && min([FinalMetricValue.orig,FinalMetricValue.zflip])>-0.40 )
    logstr = [datestr(datetime) sprintf(' -- Linear registration of scan: %s   probably failed.', scanID)];
    display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);
end

    

catch ME;
    try    
    logstr = [datestr(datetime) sprintf(' -- Linear registration failed.')];
    fprintf(LogFileID,[logstr '\n']);    
    end   
    throwAsCaller(ME)
end

end   
%%
%%
%%