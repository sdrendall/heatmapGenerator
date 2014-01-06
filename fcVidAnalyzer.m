function [heatmap, movement] = fcVidAnalyzer(movObj, cageName, path, threshold)
% [heatmap, movement] = fcVidAnalyzer(movObj, cageName, threshold)

imagesPerFrame = 30;

if ~exist('threshold', 'var')
    threshold = .1;
end

mY = movObj.Height;
mX = movObj.Width;
nFrames = movObj.NumberOfFrames;


% --- get filepaths
%[videoName, path] = uiputfile('*.avi', 'Save heatmap video as...');
videoName = ['/',cageName, '_heatmapMov.avi'];

%--- open video
hmMov = VideoWriter([path, videoName]);
open(hmMov)

% initialize arrays
heatmap = zeros(mY, mX);
hmData = zeros(mY, mX, imagesPerFrame);
for iFrame = 1:movObj.NumberOfFrames
    % --- load image
    currIm = mat2gray(rgb2gray(read(movObj, iFrame)));
    
    % ---- convert current image to bw
    currIm = 1 - im2bw(currIm, threshold);    % To be replaced with text box value
    
    % --- add bw image to heatmap array
    heatmap = heatmap + currIm;

    % create cycling index
    currIndex = mod(iFrame, imagesPerFrame);
    if currIndex == 0
        currIndex = imagesPerFrame;
    end
    
    % add current image to container array
    hmData(:,:,currIndex) = currIm;
    
    % create frames once container array is populated
    if iFrame >= imagesPerFrame
        writeVideo(hmMov, im2frame(uint8(mat2gray(sum(hmData, 3))*255), hot(256)));
    end
    
    % Add movement detection here
    if iFrame == 1
        previousIm = currIm;
    end
    difference = currIm ~= previousIm;
    movement(iFrame) = sum(difference(:));
    previousIm = currIm;
    
end

% --- close video
close(hmMov)

% --- save heatmap
% convert heatmap to log
heatmap = log(mat2gray(heatmap) + .00000001);

% normalize movement data
movement = mat2gray(movement);