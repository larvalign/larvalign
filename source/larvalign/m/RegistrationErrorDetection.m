function RegistrationErrorDetection(rootpath, deffieldPN, scanID, ext, RegOutputDir, outputDir, LogFileID)
%%
%% Registration Error Detection
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-08-30
%%
try
% dirs
TemplateImagePFN = [rootpath '\resources\Templates\Neuropil\AtlasImgMedian.mhd'];
REDPN = [ rootpath '\resources\RED\'];
IR_PFN = [ outputDir 'RegisteredScans\NP\' scanID '.' ext ];
deffieldPFN = [deffieldPN '\deformationField.mhd'];
% log
tic
logstr = [datestr(datetime) sprintf([' -- Performing automatic registration quality assessment of scan: ' scanID])];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']);


%% Preprocessing
c3d = ['"' rootpath '\resources\exe\c3d.exe" '];
[status,cmdout] = system([  c3d '"' IR_PFN '"  -info-full ']); 
assert(status==0, 'Processing failure.')
Ctmp=textscan(cmdout,'%s','Delimiter',{'  Mean Intensity     : '});
lowclip=num2str(ceil(cell2mat(textscan(Ctmp{1,1}{7,1},'%f'))));  
IRN_PFN = [RegOutputDir  scanID '.mhd'];
[status,cmdout] = system([  c3d '"' IR_PFN '"  -clip ' lowclip ' 255  -replace ' lowclip ' 0  -type uchar -compress -o ' '"' IRN_PFN '"' ]);  
assert(status==0, 'Processing failure.')
IR_PFN = IRN_PFN;

%%
%% Extract intensity and deformation field features
%% MMI
% Entire scan 
matName='MaskedMetricEntireScan';
MaskPFN = [REDPN 'CNS\CNS_Mask.mhd'];
GetSimilarityMetric(rootpath, IR_PFN, scanID, RegOutputDir, TemplateImagePFN, MaskPFN, matName )
% VNC-terminal
matName='MaskedMetric_VNC-terminal_r10';
MaskPFN = [REDPN 'VNC-terminal\landmarkpointdataoverlay_r10.mhd'];
GetSimilarityMetric(rootpath, IR_PFN, scanID, RegOutputDir, TemplateImagePFN, MaskPFN, matName )
% Thorax
matName='MaskedMetric_Thorax_r15';
MaskPFN = [REDPN 'Thorax\landmarkpointdataoverlay_r15.mhd'];
GetSimilarityMetric(rootpath, IR_PFN, scanID, RegOutputDir, TemplateImagePFN, MaskPFN, matName )
%% StrainMagnitude 
% Thorax  
matName='MaskedStrainMag_Thorax_r35';
MaskPFN = [REDPN 'Thorax\landmarkpointdataoverlay_r35.mhd'];
GetEulerianStrainMagnitude(rootpath, deffieldPFN, scanID, RegOutputDir, MaskPFN, matName)

%% 
%% Analyse extracted features
%%
%% MMI
% Entire Scan
load([RegOutputDir  'MaskedMetricEntireScan.mat'])
NCC_MI = -cell2mat(MaskedMetricValueScan(:,2));
NCC_MI = roundn(-cell2mat(MaskedMetricValueScan(:,2))*100,0);
MMI = NCC_MI(:,2);
maxMMI = 89;
ESnormedMMI = roundn(MMI/maxMMI*100, 0);
if ESnormedMMI>100, ESnormedMMI=100; end
% VNC-terminal
load([RegOutputDir  'MaskedMetric_VNC-terminal_r10.mat'])
NCC_MI = -cell2mat(MaskedMetricValueScan(:,2));                 
maxMMI = 0.8944;                      
VNCnormedMI = roundn(NCC_MI(:,2)/maxMMI*100,0);
if VNCnormedMI>100, VNCnormedMI=100; end
% Thorax
load([RegOutputDir  'MaskedMetric_Thorax_r15.mat'])
NCC_MI = -cell2mat(MaskedMetricValueScan(:,2));
NCC_MI = roundn(-cell2mat(MaskedMetricValueScan(:,2))*100,0);
NCC_MI_r15 = NCC_MI(:,2);
maxMMI = 116;
ThoraxNormedMI_r15 = NCC_MI_r15/maxMMI*100;
if ThoraxNormedMI_r15>100, ThoraxNormedMI_r15=100; end
%% Strain
load([RegOutputDir  'MaskedStrainMag_Thorax_r35.mat'])
ix=cellfun(@isempty,MaskedStrainMagValueScan(:,2)); % I/O failure
idxZero=(cell2mat(MaskedStrainMagValueScan(:,2))==0); % I/O failure
MaskedStrainMagValueScan(ix,2)={NaN};
MaskedStrainMagValueScan(idxZero,2)={NaN};
StrainMag = cell2mat(MaskedStrainMagValueScan(:,2));
% 95% percentile
medStrain = 0.7230;
madStrain = 0.2530;
% normalize strain feature
normedStrain = 100-(abs(StrainMag-medStrain)/madStrain);
normedStrain(normedStrain<0)=0;
normedStrain = round(normedStrain);
% Combined MMI strain predictor for Thorax region
ThoraxRED = roundn(ThoraxNormedMI_r15 .* normedStrain / 100, 0);
if ThoraxRED>100, ThoraxRED=100; end

%% Generate table of Quality Assessment
logstr = [datestr(datetime) sprintf(' -- Quality assessment: EntireScan: %g, VNC terminal: %g, Thoracic nerves: %g' ,abs(ESnormedMMI),abs(VNCnormedMI),abs(ThoraxRED) )];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']); 
C2 = [ MaskedStrainMagValueScan(:,1), num2cell(abs(ESnormedMMI)), num2cell(abs(VNCnormedMI)), num2cell(abs(ThoraxRED)) ];
T = cell2table(C2,'VariableNames',{'ScanID','EntireScan','VNC_terminal','Thoracic_nerves'});
QADir = [outputDir 'QualityAssessment\']; mkdir(QADir);
writetable(T, [QADir scanID '.txt'])
t=toc;
logstr = [datestr(datetime) sprintf(' -- Computation of registration quality assessment took: %g s' ,t)];
display(sprintf(logstr)), fprintf(LogFileID,[logstr '\n']); 

catch ME; 
    try    
    logstr = [datestr(datetime) sprintf(' --Quality assessment failed.')];
    fprintf(LogFileID,[logstr '\n']);    
    end   
%     throwAsCaller(ME)
end

end
%%
%%
%%