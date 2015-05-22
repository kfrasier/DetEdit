%detEdit_Settings.m

% Location of TTPP file to analyze
fn = 'J:\Rohen\TTPP\HAT02A_part1_test_TTPP2.mat';
% NOTE: LTSA.m, ID and FD files are assumed to be in the same location.

% Directory where original ltsa are located. Only used if running
% mkLTSAsessions.m
ltsaDir = 'J:\Rohen\ltsa\HAT';

% Amount of time between bouts. Encounters separated by less than this
% amount will be displayed as one bout.
gth = 0.25;    % gap time in hrs between bouts
bMax = 6; % maximum bout length in hours
minBoutDur = 75; % minimum bout length in seconds

% Frequencies between which detection spectra will be normalized:
normFreq = [10,65]; %[low,high] in kHz

% ICI display parameters
dl = 0.2; % default scale for ICI display in sec

% RL (recieved level) display parameters
RLLims = [105,175]; % y-axis limits for RL timeseries display

% LTSA display parameters
fimin = 5;     % minimum ltsa frequency for display in kHz
fimax = 100;    % maximum ltsa frequency for display in kHz
contrast = 282;
bright = 112;

falseFlag = 0; % set to 1 if you want to skip bouts that are labeled as 100%
% false detections


% Options for color labels
falseColor = [1,0,0]; % color to use for false detections (red)
resetColor = [0,0.50,0]; % color to use to reset detections (dark green)

% Colors to use for classification
colortab = [255, 153, 200; ... % type 1 pink
    218, 179, 255; ... % type 2 purple
    179, 200, 255; ... % type 3 light-blue
    174, 235, 255; ... % type 4 pale-blue
    0, 255, 255; ... % type 5 cyan
    0, 255,   0; ... % type 6 green
    255, 255,   0; ... % type 7 yellow
    255, 177, 100; ... % type 8 peach
    255,   0, 255; ... % type 9 magenta
    122,  15, 227; ... % type 10 purple
    20,  43, 140; ... % type 11 dark blue
    221, 125,   0]./255; % type 12 orange

