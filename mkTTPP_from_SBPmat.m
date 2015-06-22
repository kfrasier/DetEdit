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
baseDir = 'E:\BigDL\AntTest\'; % directory containing de_detector output
outDir = 'E:\BigDL\AntTest\TTPP\'; % directory where you want to save your TTPP file
siteName = 'AntTest'; % site name, only used to name the output file
ppThresh = 100; % minimum RL in dBpp. If detections have RL below this
% threshold, they will be excluded from the output file. Useful if you have
% an unmanageable number of detections.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if the output file exists, if not, make it
if exist(outDir,'dir')~=7
    fprintf('Creating output directory %s',outDir)
    mkdir(outDir)
end

MTT = [];
MPP = [];
MSP = [];
f = [];
dirSet = dir(baseDir);
for itr0 = 1:length(dirSet)
    if ~strcmp(dirSet(itr0).name,'.')&&~strcmp(dirSet(itr0).name,'..')
        inDir = fullfile(baseDir,dirSet(itr0).name);
        fileSet = what(inDir);
        lfs = length(fileSet.mat);
        for itr2 = 1:lfs
            thisFile = fileSet.mat(itr2);
            
            load(char(fullfile(inDir,thisFile)),'-mat','pos','rawStart',...
                'ppSignal','specClickTf','fs')
            
            if ~isempty(pos)
                % Prune detections with low received level if needed.
                keepers = find(ppSignal >= ppThresh);
                ppSignal = ppSignal(keepers);
                pos = pos(keepers,:);
                fileStart = datenum(rawStart(1,:)); 
                
                % ATTN: Calculating detection times.
                % This assumes that times in the position vector "pos" 
                % are relative to the start time of the first raw file. 
                posDnum = (pos(:,1)/(60*60*24)) + fileStart +...
                    datenum([2000,0,0,0,0,0]);
                
                % store to vectors:
                MTT = [MTT; posDnum];
                MPP = [MPP; ppSignal];
                MSP = [MSP; specClickTf(keepers,:)];
                
                clickTimes = [];
                hdr = [];
                specClickTf = [];
                ppSignal = [];
                if isempty(f)
                    f = 0:(fs/(2*1000))/(size(specClickTf,2)-1):(fs/(2*1000));
                end
            end
            fprintf('Done with file %d of %d \n',itr2,lfs)
        end
    end
    fprintf('Done with directory %d of %d \n',itr0,length(dirSet))

end


save(fullfile(outDir,[siteName,'_TTPP','.mat']),'MTT','MPP','MSP','f',...
    '-v7.3')
