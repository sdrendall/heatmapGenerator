function usrData = makeHeatmap(usrData)
% creates a heatmap from 

% --- check for insufficient data
if isempty(usrData.imagePaths)
    errordlg('No images loaded');
    return
end

if isempty(usrData.cropWindow)
    cropWindowSpecified = false;
end

if ~exist('usrData.threshold', 'var')
    usrData.threshold = .1;
end

if ~exist('usrData.frameWindow', 'var')
	usrData.frameWindow = 30;
end
	

% --- get filepaths
[videoName, videoPath] = uiputfile('*.avi', 'Save heatmap video as...');

% --- open video
hmMov = VideoWriter([videoPath, videoName]);
open(hmMov)

% --- For each image
for i = 1:length(usrData.imagePaths)
% --- load image
    currIm = mat2gray(rgb2gray(imread(usrData.imagePaths{i})));
    
% --- crop image
if cropWindowSpecified
    currIm = cropImage(currIm, usrData.cropWindow);
end

% ---- convert current image to bw
currIm = 1 - im2bw(currIm, usrData.threshold);    % To be replaced with text box value

% --- add bw image to heatmap array
if i == 1
    heatmap = zeros(size(currIm));
end
heatmap = heatmap + currIm;

% --- generate heatmap movie frame
if i == 1
    % initialize container array
    [nr, nc] = size(currIm);
    hmData = zeros(nr, nc, usrData.frameWindow);
end

% create cycling index
currIndex = mod(i, usrData.frameWindow);
if currIndex == 0
    currIndex = usrData.frameWindow;
end

% add current image to container array
hmData(:,:,currIndex) = currIm;

% create frames once container array is populated
if i >= usrData.frameWindow
    writeVideo(hmMov, im2frame(uint8(mat2gray(sum(hmData, 3))*255), hot(256)));
end
end

% --- close video
close(hmMov)

% --- save heatmap
% convert heatmap to log
usrData.heatmap = log(mat2gray(heatmap) + .00000001);

