%% transform frame to find body position and align its orientation
function [alignedImageBS, alignedImageBS2, P1, P2, mig2] = TrackBody(FRaw,FRawSmooth,bckImg)
% perform edge detection on the background subtracted frame
s = size(FRaw);
img = imadjust(bckImg-FRawSmooth,[],[],1);
img = edge(img,'canny',0.5 ,1+sqrt(3));
mig2 = img;

% iteratively fill, dilate and erode image until it fills an area
% approximately the body size on the fly
it = 1;
while(sum(sum(img)) < 6000 && it  < 10)
    se = strel('square',it);
    img = imdilate(img,se);
    img = imerode(img,se);
    img = imdilate(img,se);
    img = imfill(img,'holes');
    img = imerode(img,se);
    it = it + 1;
end
% Select the largest connected componnent and mask out all the others
CC = bwconncomp(img,4);
if length(CC.PixelIdxList) > 1
    lengths = zeros(1,length(CC.PixelIdxList));
    means = zeros(1,length(CC.PixelIdxList));
    for j=1:length(lengths)
        means(j) = mean(img(CC.PixelIdxList{j}));
        lengths(j) = length(img(CC.PixelIdxList{j}));
    end
    [~,idx] = max(means);
    if lengths(idx) < 2000
        [~,idx] = max(lengths);
    end
    temp = img;
    temp(:) = 0;
    temp(CC.PixelIdxList{idx}) = 1;
    mask = temp;
else
    mask = img;
end
img = immultiply(mask,img);

% Extract centroind and orientation info from the largest connected
% componnent
stats = regionprops(img, 'Orientation','Centroid');
if(isempty(stats))
    clearvars stats
    stats.Centroid(1)=s(2)/2;
    stats.Centroid(2)=s(1)/2;
    stats.Orientation=0;
end
T = affine2d([1 0 0 ;0 1 0; s(2)/2-stats.Centroid(1) s(1)/2-stats.Centroid(2) 1]);
alignedImageBSCent = imwarp(bckImg-FRaw, T,'OutputView', imref2d(s), 'interp', 'linear');
alignedImageBS = imrotate(alignedImageBSCent, -90-stats.Orientation, 'crop');
P1(1) = stats.Centroid(1);
P1(2) = stats.Centroid(2);
P1(3) = stats.Orientation;

% re-center the frame so that fly is in the center and vertically oriented
alignedImageBSCent2 = imwarp(FRaw, T,'OutputView', imref2d(s), 'interp', 'linear');
alignedImageBS2 = imrotate(alignedImageBSCent2, -90-stats.Orientation, 'crop');

% Re center info (in case 180� off)
centeredImg = imwarp(img, T,'OutputView', imref2d(s), 'interp', 'linear');
aligImg2 = imrotate(centeredImg, -90-stats.Orientation+180, 'crop');
stats2 = regionprops(aligImg2, 'Orientation','Centroid');
if(isempty(stats2))
    clearvars stats2
    stats2.Centroid(1)=s(2)/2;
    stats2.Centroid(2)=s(1)/2;
    stats2.Orientation=0;
end
P2(1) = P1(1) + stats2.Centroid(1);
P2(2) = P1(2) + stats2.Centroid(2);
P2(3) = stats.Orientation;

end

