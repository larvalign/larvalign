function GetSimilarityMetric(rootpath, IR_PFN, scanID, RegOutputDir, AtlasTemplatePFN, MaskPFN, matName )
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-08-31
%%
try
%% Evaluate pairwise s to atlas registrations
MaskedMetricValueScan = {scanID, [NaN,NaN] };
if ~exist(IR_PFN ,'file')
    return;
end
MaskedMetricValueScan = {scanID, GetMaskedMetricValue(rootpath, AtlasTemplatePFN, IR_PFN, MaskPFN) };
save([RegOutputDir  matName '.mat' ], 'MaskedMetricValueScan');

catch ME;  
    throwAsCaller(ME)
end

end
%%
%%
%%