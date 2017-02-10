%%
%% Image registration framework for registration of the larval CNS of Drosophila melanogaster
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-06-09
%% 
function msg = larvalignMain(varargin)
% setdbprefs('errorhandling','report')

warning('off','all');
%% Start GUI
if isempty(varargin)
    try    
    larvalign_GUI_callback = larvalign_GUI; 
    if ~isfield(larvalign_GUI_callback,'Mode'), msg=[]; return, end
    if strcmp(larvalign_GUI_callback.Mode,'single')
        OutputDir = larvalign_GUI_callback.OutputDir;
        LSM_PFN = larvalign_GUI_callback.LSM_PFN;
        ChannelPosNP_NT_GE = str2num(larvalign_GUI_callback.ChannelPosNP_NT_GE);
        LSMchannelNP = num2str(ChannelPosNP_NT_GE(1));
        LSMchannelNT = num2str(ChannelPosNP_NT_GE(2));
        LSMchannelGE = num2str(ChannelPosNP_NT_GE(3));
        CPUGPU = larvalign_GUI_callback.CPUGPU;
        LandmarksTemplatePFN = larvalign_GUI_callback.LandmarksTemplatePFN;
        LandmarksSubjectPFN = larvalign_GUI_callback.LandmarksSubjectPFN;
        if isempty(LandmarksTemplatePFN) && isempty(LandmarksSubjectPFN)
            varargin={'OutputDir', OutputDir, 'Method', 'FullyAutomatic', 'CPUGPU', CPUGPU, 'LSM_PFN', LSM_PFN, 'LSMchannelNP', LSMchannelNP, 'LSMchannelNT', LSMchannelNT, 'LSMchannelGE', LSMchannelGE};   
        else
            varargin={'OutputDir', OutputDir, 'Method', 'SemiAutomatic', 'CPUGPU', CPUGPU, 'LSM_PFN', LSM_PFN, 'LSMchannelNP', LSMchannelNP, 'LSMchannelNT', LSMchannelNT, 'LSMchannelGE', LSMchannelGE,...
                'LandmarksTemplatePFN',LandmarksTemplatePFN,'LandmarksSubjectPFN',LandmarksSubjectPFN };  
        end     
        msg = MainIRF(varargin{:});
        if ~strcmp(msg,'0'), display(sprintf(msg)); end
                
    elseif strcmp(larvalign_GUI_callback.Mode,'batch')
        OutputDir = larvalign_GUI_callback.OutputDir;
        InputDir = larvalign_GUI_callback.InputDir;
        ChannelPosNP_NT_GE = str2num(larvalign_GUI_callback.ChannelPosNP_NT_GE);
        LSMchannelNP = num2str(ChannelPosNP_NT_GE(1));
        LSMchannelNT = num2str(ChannelPosNP_NT_GE(2));
        LSMchannelGE = num2str(ChannelPosNP_NT_GE(3));  
        CPUGPU = larvalign_GUI_callback.CPUGPU;
        LandmarksTemplatePFN = larvalign_GUI_callback.LandmarksTemplatePFN;
        LandmarksSubjectPN = larvalign_GUI_callback.LandmarksSubjectPN;        
        LsmInfo=dir(fullfile(InputDir,'*.lsm'));
        TiffInfo=dir(fullfile(InputDir,'*.tiff'));
        TifInfo=dir(fullfile(InputDir,'*.tif'));
        filesLsm={};filesTiff={};filesTif={};
        for f=1:size(LsmInfo,1)
            filesLsm{f} = LsmInfo(f).name;            
        end
        for f=1:size(TiffInfo,1)
            filesTiff{f} = TiffInfo(f).name;            
        end
        for f=1:size(TifInfo,1)
            filesTif{f} = TifInfo(f).name;            
        end
        fileNames=[filesLsm filesTiff filesTif];
        if isempty(LandmarksTemplatePFN) && isempty(LandmarksSubjectPN)
        for s=1:length(fileNames)  
            LSM_PFN = fullfile(InputDir, fileNames{s});
            varargin={'OutputDir', OutputDir, 'Method', 'FullyAutomatic', 'CPUGPU', CPUGPU, 'LSM_PFN', LSM_PFN, 'LSMchannelNP', LSMchannelNP, 'LSMchannelNT', LSMchannelNT, 'LSMchannelGE', LSMchannelGE}; 
            msg = MainIRF(varargin{:});
            if ~strcmp(msg,'0'), display(sprintf(msg)); end
        end
        else
        for s=1:length(fileNames)  
            LSM_PFN = fullfile(InputDir, fileNames{s});
            [pathstr,name,ext] = fileparts(fileNames{s});
            LandmarksSubjectPFN = [LandmarksSubjectPN '\' name '.points'];
            varargin={'OutputDir', OutputDir, 'Method', 'SemiAutomatic', 'CPUGPU', CPUGPU, 'LSM_PFN', LSM_PFN, 'LSMchannelNP', LSMchannelNP, 'LSMchannelNT', LSMchannelNT, 'LSMchannelGE', LSMchannelGE,...
                'LandmarksTemplatePFN',LandmarksTemplatePFN,'LandmarksSubjectPFN',LandmarksSubjectPFN };                          
            msg = MainIRF(varargin{:});
            if ~strcmp(msg,'0'), display(sprintf(msg)); end
        end            
        end
    end
        
    catch ME
        display(ME)
        return
    end 
    
else
%% Command line call
msg = MainIRF(varargin{:});


end
%%
%%
%%