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

% Last Modified by GUIDE v2.5 12-May-2019 20:46:58

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
    % Get default command line output from handles structure.
    varargout{1} = handles.output;

    handles.downSample = [10 5];
    handles.maxNumImages = 10;
    handles.numImagesToProcess = 5;

    handles.imds = imageDatastore(uigetdir(), 'includesubfolders',true,'LabelSource','foldernames');
    processFolder(hObject, handles.imds, handles);
    
    guidata(hObject, handles);

% --- Executes on button press in btnRun.
function btnRun_Callback(hObject, eventdata, handles)
    % Use splitEachLabel function to separate the test/training sets
    [handles.trainingSet, handles.testSet] = splitEachLabel(handles.imds, 0.5, 'randomize');
    handles.classes = unique(handles.imds.Labels);

    handles.numImages = length(handles.imds.Files);
    handles.numTrainingImages = length(handles.trainingSet.Files);
    handles.numTestImages = length(handles.testSet.Files);
    handles.numClasses = length(handles.classes);
    
    %Read in training images
    handles.trainingColumns = processImageSet(handles.trainingSet, handles); 

    %handles.testColumns = processImageSet(handles.testSet, handles);
    
    %for loop for each image
    k = 1;
    correct = 0;
    %tested = 0;
    for i = 1 : handles.numClasses
        for j = 1 : handles.numImagesToProcess
            [img, info] = readimage(handles.testSet, k);
            imshow(img, 'parent', handles.imgTest);
            set(handles.lblTestClass, 'String', strcat('Class: ', string(info.Label)));
            
            [dist, index] = distanceCalc(handles, columniseImage(handles, img)); 
  
            %Weak code, assuming 10 img, evenly split. 
            [predictedImg, predictedInfo] = readimage(handles.trainingSet,(index*5)-4);
            imshow(predictedImg, 'parent', handles.imgClass);
            set(handles.lblTrainingClass, 'String', strcat('Class: ', string(predictedInfo.Label)));
            
            if index == i
                %hip hip hooray
                set(handles.lblResult, 'String', 'Correct');
                set(handles.lblResult, 'ForegroundColor', 'green');
                correct = correct + 1;
                %tested = tested + 1;
            else
                set(handles.lblResult, 'String', 'Incorrect');
                set(handles.lblResult, 'ForegroundColor', 'red');
                %tested = tested + 1;
                pause(2);
            end

            k = k + 1;
            set(handles.lblAccuracy, 'String', strcat('Accuracy: ', num2str(correct/(k-1), 4)));
            pause(0.5);
        end
    end

 function columns = processImageSet(imageSet, handles)
    % Preallocate memory for 50x5x40 array
    columns = zeros(prod(handles.downSample), handles.numImagesToProcess, handles.numClasses);
    
    k = 1;
    %For the 40 classes
    for i = 1 : handles.numClasses
        %For the 5 images in each class
        for j = 1 : handles.numImagesToProcess
            %Pass in kth image, increase 1 each run, as all training images are
            %together
            img = columniseImage(handles, readimage(imageSet, k));
            columns(:, j, i) = img;
            k = k + 1;
        end
    end   
    
function img = columniseImage(handles, img)
    %If RGB, make greyscale
    if ndims(img) == 3
        img = rgb2gray(img);
    end

    % Resize to 10x5
    img = imresize(img, handles.downSample);

    % Reshape to column.
    img = double(reshape(img, prod(handles.downSample), 1));

    % Normalize
    img = img / max(img);

function [dist, index] = distanceCalc(handles, y)
    dist = zeros(length(handles.classes),1);
    for i = 1 : handles.numClasses
        x = handles.trainingColumns(:,:,i);
        dist(i) = sum((y - x*(x\y)) .^ 2);
    end
    [dist,index] = min(dist);
    
function processFolder(hObject, imds, handles)
    tbl = countEachLabel(imds);

    minSetCount = min(tbl{:,2}); 
    
    minSetCount = min(handles.maxNumImages, minSetCount);

    % Use splitEachLabel function to trim the set.
    handles.imds = splitEachLabel(imds, minSetCount, 'randomize');
    
    % Save handles
    guidata(hObject, handles);
    
% --- Executes on button press in btnLoad.
function btnLoad_Callback(hObject, eventdata, handles)
    imds = imageDatastore(uigetdir(), 'includesubfolders',true,'LabelSource','foldernames');
    processFolder(hObject, imds, handles);
