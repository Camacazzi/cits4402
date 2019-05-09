function varargout = cits4402(varargin)
% CITS4402 MATLAB code for cits4402.fig
%      CITS4402, by itself, creates a new CITS4402 or raises the existing
%      singleton*.
%
%      H = CITS4402 returns the handle to a new CITS4402 or the handle to
%      the existing singleton*.
%
%      CITS4402('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CITS4402.M with the given input arguments.
%
%      CITS4402('Property','Value',...) creates a new CITS4402 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cits4402_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cits4402_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cits4402

% Last Modified by GUIDE v2.5 06-May-2019 14:48:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cits4402_OpeningFcn, ...
                   'gui_OutputFcn',  @cits4402_OutputFcn, ...
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

% --- Executes just before cits4402 is made visible.
function cits4402_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cits4402 (see VARARGIN)

% Choose default command line output for cits4402
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes cits4402 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = cits4402_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

handles.downSample = [10 5];
%handles.images = 10;
%handles.trainNum = 5;
%handles.testNum = 5;

imds = imageDatastore(uigetdir(), 'includesubfolders',true,'LabelSource','foldernames');

tbl = countEachLabel(imds);

minSetCount = min(tbl{:,2}); 
maxNumImages = 10;
handles.numImagesPerClass = 5;
minSetCount = min(maxNumImages,minSetCount);

% Use splitEachLabel method to trim the set.
imds = splitEachLabel(imds, minSetCount, 'randomize');

[trainingSet, testSet] = splitEachLabel(imds, 0.5, 'randomize');
handles.trainingSet = trainingSet;
handles.testSet = testSet;
handles.classes = unique(imds.Labels);

handles.numImages = length(imds.Files);
handles.numTrainingImages = length(trainingSet.Files);
handles.numTestImages = length(testSet.Files);
handles.numClasses = length(handles.classes);

%Read in training images
handles.trainedSet = readTrainingSet(hObject, handles); 

yhats = zeros(prod(handles.downSample,length(handles.numClasses)));
for i = 1 : handles.numClasses
    x = handles.trainedSet(:,i);
    %yhats(:,i) = x\specific test image
end

% --- Executes on button press in selectfolder.
function selectfolder_Callback(hObject, eventdata, handles)
% hObject    handle to selectfolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in execute.
function execute_Callback(hObject, eventdata, handles)
% hObject    handle to execute (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function trainedSet = readTrainingSet(hObject, handles)
%preallocate memory for 50x5x40 array
trainedSet = zeros(prod(handles.downSample), handles.numImagesPerClass, handles.numClasses);

%test = zeros(prod(handles.downSample), handles.testNum, length(classes));
trainingIndexes = zeros(handles.numClasses);

for i = 1 : handles.numTrainingImages
    [img,info] = readimage(handles.trainingSet,i);
    class = info.Label;
   
    %classIndex = find(strcmp(handles.classes, class))
    classIndex = strfind(handles.classes, class);
    trainingIndexes(classIndex) = trainingIndexes(classIndex) + 1;
    img = columniseImage(hObject, handles, img);
    trainedSet(:, classIndex, trainingIndexes(classIndex)) = img;
end

%z = 1
%For the 40 classes
%for i = 1 : length(classes)
    %For the 5 images in each class
    %for j = 1 : handles.trainNum
        %Pass in zth image, increase 1 each run, as all training images are
        %together
        %img = columniseImage(hObject, handles, readimage(train,z));
        %train(:,j,i) = img;
        %z = z + 1;
    %end
%end    
    
function img = columniseImage(hObject, handles, img)
%If RGB, make greyscale
if ndims(img) == 3
    img = rgb2gray(img);
end

%Resize to 10x5
img = imresize(img, handles.downSample);

%Reshape to column
img = double(reshape(img, prod(handles.downSample), 1));

%normalize
img = img / max(img);