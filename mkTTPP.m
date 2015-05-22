% mkTTPP.m

% Script takes output from de_detector.m and put it into a format for use in
% detEdit.
% Output:
% A TTPP.m file containing 4 variables: 
%   MTT: An Nx2 vector of detection start and end times, where N is the
%   number of detections
%   MPP: An Nx1 vector of recieved level (RL) amplitudes.
%   MSP: An NxF vector of detection spectra, where F is dictated by the
%   parameters of the fft used to generate the spectra and any  
%   normalization preferences.
%   f = An Fx1 frequency vector associated with MSP

clearvars

% Setup variables:
baseDir = 'H:\metadata\'; % directory containing de_detector output
outDir = 'J:\Rohen\TTPP\'; % directory where you want to save your TTPP file
siteName = 'HAT02A_part1_test'; % site name, only used to name the output file
ppThresh = 120; % minimum RL in dBpp. If detections have RL below this
% threshold, they will be excluded from the output file. Useful if you have
% an unmanageable number of detections.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if the output file exists, if not, make it
if ~exist(outDir,'dir')==7
    fprintf('Creating output directory %s',outDir)
    mkdir(outDir)
end

clickTimesVec = [];
ppSignalVec = [];
specClickTfVec = [];

dirSet = dir(baseDir);
for itr0 = 1:length(dirSet)
    if ~strcmp(dirSet(itr0).name,'.')&&~strcmp(dirSet(itr0).name,'..')
        inDir = fullfile(baseDir,dirSet(itr0).name);
        fileSet = what(inDir);
        lfs = length(fileSet.mat);
        for itr2 = 1:lfs
            thisFile = fileSet.mat(itr2);
            
            load(char(fullfile(inDir,thisFile)),'-mat','clickTimes','hdr',...
                'ppSignal','specClickTf','f')
            
            if ~isempty(clickTimes)
                keepers = find(ppSignal >= ppThresh);
                ppSignal = ppSignal(keepers);
                clickTimes = clickTimes(keepers,:);
                fileStart = datenum(hdr.start.dvec);
                posDnum = (clickTimes(:,1)/(60*60*24)) + fileStart +...
                    datenum([2000,0,0,0,0,0]);
                clickTimesVec = [clickTimesVec; posDnum];
                ppSignalVec = [ppSignalVec; ppSignal];
                if iscell(specClickTf)
                    spv = cell2mat(specClickTf');
                    specClickTfVec = [specClickTfVec; spv(:,keepers)'];
                else
                    specClickTfVec = [specClickTfVec; specClickTf(keepers,:)];
                end
                clickTimes = [];
                hdr = [];
                specClickTf = [];
                ppSignal = [];
            end
            fprintf('Done with file %d of %d \n',itr2,lfs)
        end
    end
    fprintf('Done with directory %d of %d \n',itr0,length(dirSet))

end

MTT = clickTimesVec;
MPP = ppSignalVec;
MSP = specClickTfVec;

save(fullfile(outDir,[siteName,'_TTPP','.mat']),'MTT','MPP','MSP','f',...
    '-v7.3')
