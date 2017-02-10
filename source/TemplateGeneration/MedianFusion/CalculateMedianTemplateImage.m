%% SEAM@2015-10-29
%% Compute median template image of average deformation images
%%
        
%% input
scanListPFN = 'DrosoTemplateScansList.txt'; % list of scans used for population atlas
atlasAvgDefPN = 'Drosophila_pop_avg_scans\'; % output directory of register-population-drosophila.py
fileID = fopen(scanListPFN);
ScansList = textscan(fileID,'%s','Delimiter',{'\r\n'})
fclose(fileID);
ScansList = ScansList{1,1};


%% load average deformation images
for a=1:length(ScansList)       
    registerDir = [ atlasAvgDefPN '\inv' ScansList{a} ]; 
        
    if exist([ registerDir  '\result.mhd'],'file')
        sprintf('Reading AvgDefImg: %i, InvScanID: %s', a, ScansList{a}) 
        [AvgDefImg, info]=read_mhd([ registerDir  '\result.mhd']);
        AvgDefImg.data = uint8(AvgDefImg.data);
        VecAvgDefImgs(a) = AvgDefImg;
    else
        error(['Image does not exist at: ' registerDir])
    end              
end
clear AvgDefImg;


%% compute mean and median template images
ImgOrig = VecAvgDefImgs(1).origin;
ImgSp = VecAvgDefImgs(1).spacing;
ImgOrient = VecAvgDefImgs(1).orientation;
ImgSize = VecAvgDefImgs(1).size;
TemplateImgMean = ImageType(ImgSize, ImgOrig, ImgSp, ImgOrient);
TemplateImgMedian = ImageType(ImgSize, ImgOrig, ImgSp, ImgOrient);

for x=1:ImgSize(1)    
    for y=1:ImgSize(2)
        for z=1:ImgSize(3)             
            for a=1:length(ScansList)
               idx=[x y z];
               AvgDefImgsVoxIntens(a) = VecAvgDefImgs(a).GetPixel(idx');              
            end
            TemplateImgMean.data(idx(1),idx(2),idx(3)) = mean(AvgDefImgsVoxIntens);      
            TemplateImgMedian.data(idx(1),idx(2),idx(3)) = median(AvgDefImgsVoxIntens);           
        end
    end
end


%% write result template images
TemplateImgMean.data = uint8(TemplateImgMean.data);
write_mhd([TemplateAvgDefPN 'TemplateImgMean.mhd'], TemplateImgMean, 'ElementType', 'uint8')

TemplateImgMedian.data = uint8(TemplateImgMedian.data);
write_mhd([TemplateAvgDefPN 'TemplateImgMedian.mhd'], TemplateImgMedian, 'ElementType', 'uint8')


%%
%%
%%