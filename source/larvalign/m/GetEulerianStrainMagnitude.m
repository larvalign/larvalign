function GetEulerianStrainMagnitude(rootpath, deffieldPFN, scanID, RegOutputDir, MaskPFN, matName )
%%
%% Author: S.E.A. Muenzing
%% SEAM@2016-11-30
%%     
try
%% dirs & exe
exeDir = [rootpath '\resources\exe\'];
c3d = ['"' exeDir 'c3d.exe" '];
%%
%% Calculate Eulerain strain magnitude
MaskedStrainMagValueScan = {scanID, NaN };
[status,cmdout] = system( [c3d  ' -strain '  '"' deffieldPFN '"' ' '  '"' MaskPFN '"' ' -background 0 -verbose -pim ForegroundQuantile -threshold 95% inf 1 0']);
assert(status==0 , [datestr(datetime) sprintf([' -- Processing failure.\n' cmdout])] )  
C=textscan(cmdout,'%s');
MaskedStrainMagValueScan = {scanID,   str2num(C{1,1}{9,1}) };
save([RegOutputDir '\' matName '.mat' ], 'MaskedStrainMagValueScan');

catch ME;  
    throwAsCaller(ME)
end

end
%%
%%
%%