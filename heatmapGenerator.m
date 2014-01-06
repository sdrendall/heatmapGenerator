function varargout = heatmapGenerator(varargin)
% HEATMAPGENERATOR MATLAB code for heatmapGenerator.fig
%      HEATMAPGENERATOR, by itself, creates a new HEATMAPGENERATOR or raises the existing
%      singleton*.
%
%      H = HEATMAPGENERATOR returns the handle to a new HEATMAPGENERATOR or the handle to
%      the existing singleton*.
%
%      HEATMAPGENERATOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HEATMAPGENERATOR.M with the given input arguments.
%
%      HEATMAPGENERATOR('Property','Value',...) creates a new HEATMAPGENERATOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before heatmapGenerator_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to heatmapGenerator_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help heatmapGenerator

% Last Modified by GUIDE v2.5 31-Aug-2013 21:02:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @heatmapGenerator_OpeningFcn, ...
                   'gui_OutputFcn',  @heatmapGenerator_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before heatmapGenerator is made visible.
function heatmapGenerator_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to heatmapGenerator (see VARARGIN)
global usrData

axes(handles.mainWindow), axis off

% Choose default command line output for heatmapGenerator
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes heatmapGenerator wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = heatmapGenerator_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in loadTimelapse.
function loadTimelapse_Callback(hObject, eventdata, handles)
% hObject    handle to loadTimelapse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% global variable to store data
global usrData

% get image file paths
[usrData.imagePaths, usrData.filenames] = getImagePath();

% load and display first image
usrData.firstImage = imread(usrData.imagePaths{1});
usrData.currIm = usrData.firstImage;
axes(handles.mainWindow), imshow(usrData.currIm);


% --- Executes on button press in specifyCropWindow.
function specifyCropWindow_Callback(hObject, eventdata, handles)
% Asks user to specify four corners of a window to crop to
global usrData

if isempty(usrData.currIm)
    errordlg('No images loaded');
    return

% run if images are loaded
else
    % get corners
    axes(handles.mainWindow), imshow(usrData.currIm)
    corners = ginput(4);
    % convert to coordinates for cropping [firstRow lastRow firstColumn lastColumn]
    usrData.cropWindow = [floor(min(corners(:,2))) ceil(max(corners(:,2))) ...
        floor(min(corners(:,1))) ceil(max(corners(:,1)))];
    % crop and redisplay current image
    usrData.currIm = cropImage(usrData.currIm, usrData.cropWindow);
    axes(handles.mainWindow), imshow(usrData.currIm)
end


% --- Executes on button press in generateHeatmap.
function generateHeatmap_Callback(hObject, eventdata, handles)
% hObject    handle to generateHeatmap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global usrData
frameWindow = str2double(get(handles.imsPerFrame,'String'));

% --- check for insufficient data
if isempty(usrData.imagePaths)
    errordlg('No images loaded');
    return
end

if isempty(usrData.cropWindow)
    cropWindowSpecified = false;
else
    cropWindowSpecified = true;
end

if ~exist('usrData.threshold', 'var')
    usrData.threshold = .1;
end

% --- get filepaths
[videoName, videoPath] = uiputfile('*.avi', 'Save heatmap video as...');

% --- open video
hmMov = VideoWriter([videoPath, videoName]);
open(hmMov)

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
    hmData = zeros(nr, nc, frameWindow);
end

% create cycling index
currIndex = mod(i, frameWindow);
if currIndex == 0
    currIndex = frameWindow;
end

% add current image to container array
hmData(:,:,currIndex) = currIm;

% create frames once container array is populated
if i >= frameWindow
    writeVideo(hmMov, im2frame(uint8(mat2gray(sum(hmData, 3))*255), hot(256)));
end
end

% --- close video
close(hmMov)

% --- save heatmap
% convert heatmap to log
usrData.heatmap = log(mat2gray(heatmap) + .00000001);

% display heatmap
axes(handles.mainWindow), imshow(usrData.heatmap, []), colormap(jet)


% --- Executes on button press in generateTimelapse.
function generateTimelapse_Callback(hObject, eventdata, handles)
% hObject    handle to generateTimelapse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function croppedImage = cropImage(image, cropWindow)
% croppedImage = cropImage(A, cropWindow)
%
% Crops image (A) to coordinates specified in the array cropWindow
% cropWindow format: [firstRow lastRow firstColumn lastColumn]

croppedImage = image(cropWindow(1):cropWindow(2), cropWindow(3):cropWindow(4),:);


% --- Executes on button press in saveMainDisplay.
function saveMainDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to saveMainDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, path] = uiputfile('*.png', 'Save as...');
export_fig(handles.mainWindow, [path, filename])


function imsPerFrame_Callback(hObject, eventdata, handles)
% hObject    handle to imsPerFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of imsPerFrame as text
%        str2double(get(hObject,'String')) returns contents of imsPerFrame as a double


% --- Executes during object creation, after setting all properties.
function imsPerFrame_CreateFcn(hObject, eventdata, handles)
% hObject    handle to imsPerFrame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

set(hObject, 'String', '30');


% --- Executes on selection change in staticHeatmapColormapPopup.
function staticHeatmapColormapPopup_Callback(hObject, eventdata, handles)
% hObject    handle to staticHeatmapColormapPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns staticHeatmapColormapPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from staticHeatmapColormapPopup
global usrData

axes(handles.mainWindow), imshow(usrData.heatmap, [])

% Change colormap to selection
switch get(hObject, 'Value')
    case 1
        colormap(jet)
    case 2
        colormap(hsv)
    case 3
        colormap(hot)
    case 4
        colormap(cool)
    case 5
        colormap(spring)
    case 6
        colormap(summer)
    case 7
        colormap(autumn)
    case 8
        colormap(winter)
    case 9
        colormap(gray)
    case 10
        colormap(bone)
    case 11
        colormap(copper)
    case 12
        colormap(pink)
    case 13
        colormap(lines)
end

    
% --- Executes during object creation, after setting all properties.
function staticHeatmapColormapPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to staticHeatmapColormapPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in movementDetection.
function movementDetection_Callback(hObject, eventdata, handles)
% hObject    handle to movementDetection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global usrData

usrData.movementPerImage = quantifyMovement(usrData.imagePaths);
axes(handles.mainWindow), plot(usrData.movementPerImage)


function movement = quantifyMovement(paths, cropWindow)
% movement = quantifyMovement(image paths)
%
% Movement detection stratagy -- displacement derivative sensor
%
% Determines how much a black mouse has moved from one picture to the next
% based on the change in which pixels the mouse occupies
%
% Returns a normalized array of how much the mouse 'moved' from each
% picture to the next

if ~exist('paths', 'var')
    paths = getImagePath;
end

currentImage = im2bw(mat2gray(rgb2gray(imread(paths{1}))), .1);

for i = 2:length(paths)
    if exist('cropWindow', 'var')
        currentImage = cropImage(currentImage, cropWindow);
    end
    previousImage = currentImage;
    currentImage = im2bw(mat2gray(rgb2gray(imread(paths{i}))), .1);
    difference = currentImage ~= previousImage;
    movement(i - 1) = sum(difference(:));
end  

% Normalize
movement = mat2gray(movement);
