% mkLTSAsessions.m

% This script operates on a set of LTSAs (Long Term Spectral Averages) 
% associated with detections contained within a TTPP file produced by 
% mkTTPP.m. The idea is to compute small ltsas for each bout of detections,
% rather than loading entire ltsas.

% Script is modified from original version by JA Hildebrand (8-12-2014) and 
% SM Wiggins (03-10-2014).
% Updates by KE Frasier 05-19-2015

% Inputs:
% 1) Settings are read in from detEdit_settings.m

% 2) LTSAs, which are expected to be located in a single directory (see
% detEdit_settings.m)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars
tic % start timer

% Get input settings by reading setup script
detEdit_Settings

gt = gth*60*60;    % convert min gap time into seconds

if ~exist(fn,'file');
    disp(['Error: File Does Not Exist: ',fn])
    return
end

% Generate LTSA session output file name
[inPath,inTTPP,inExt] = fileparts(fn);
inLTSA = strrep(inTTPP,'TTPP','LTSA');
fnLTSA = fullfile(inPath,[inLTSA,inExt]);

% load detections from TTPP file
load(fn)

% get ltsa file names for a specific site name and deployment number
d = dir(fullfile(ltsaDir,'*.ltsa'));
fnames = char(d.name);
nltsas = length(d);

% load up rawfile start times
disp('reading ltsa headers, please be patient ...')
doff = datenum([2000 0 0 0 0 0]);   % convert ltsa time to millenium time

% PARAMS is a structure used to hold various LTSA parameters. This storage 
% method is consistent with code used in TRITON (SM Wiggins and MA Roch).
global PARAMS
sTime = zeros(nltsas,1); 
eTime = zeros(nltsas,1);
for k = 1:nltsas
    PARAMS.ltsa.inpath = ltsaDir;
    PARAMS.ltsa.infile = fnames(k,:);
    read_ltsahead_GoM
    sTime(k) = PARAMS.ltsa.start.dnum + doff;  % start time of ltsa files
    eTime(k) = PARAMS.ltsa.end.dnum + doff;    % end time of ltsa files
    
    % Retain all rawfile start times for all ltsas as matlab datenums
    rfTimeStart{k,:} = PARAMS.ltsa.dnumStart + doff;
    rfTimeEnd{k,:} = PARAMS.ltsa.dnumEnd + doff; 
end
disp('done reading ltsa headers')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Identify bouts in detection data

% Find edges (start and end times) of bouts or sessions by looking for
% large time gaps between detections
dt = diff(MTT)*24*60*60; % time between detections, convert from to seconds

I = find(dt>gt);          % find start of gaps
sb = [MTT(1);MTT(I+1)];   % start time of bout
eb = [MTT(I);MTT(end)];   % end time of bout
dd = MTT(end)-MTT(1);     % deployment duration [d]

nb = length(sb);        % number of bouts

% limit the length of a bout
blim = bMax/24;       % bout length limit in days
ib = 1;

% Step through bouts and split any that are larger than the maximum allowed
% duration.
while ib <= nb

    bd = (eb - sb);   %duration bout in sec
    if (bd(ib) > blim)      % find long bouts
        nadd = ceil(bd(ib)/blim) - 1; % number of bouts to add
        for imove = nb : -1: (ib +1)
            sb(imove+nadd)= sb(imove);
        end
        for iadd = 1 : 1: nadd
            sb(ib+iadd) = sb(ib) + blim*iadd;
        end
        for imove = nb : -1 : ib 
            eb(imove+nadd) = eb(imove);
        end
        for iadd = 0 : 1 : (nadd - 1)
            eb(ib+iadd) = sb(ib) + blim*(iadd+1);
        end
        nb = nb + nadd; % update bout total if a bout has been split
        ib = ib + nadd;
    end
    ib = ib + 1;
end
bd = (eb - sb);   %duration bout in sec

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loop over the number of bouts (sessions), and compute LTSA for each one.
fprintf('%d sessions to process ', nb)
k = 1;
while (k <= nb)
    if eb(k) - sb(k) < minBoutDur / (60*60*24)
        fprintf('Session less than %d sec, so skip it',minBoutDur)
        k = k + 1;
        continue
    end
    
    % find which ltsa to use and get pwr and pt vectors
    K = [];
    K = find(sTime <= sb(k) & eTime >= eb(k));
    % find which rawfiles to plot ltsa
    if ~isempty(K)
        if length(K)>1
            disp('WARNING: K is multiple elements long, using only first value')
            K = K(1);
        end
        L = [];
        L = find(rfTimeStart{K,:} >= sb(k) & rfTimeStart{K,:} <= eb(k));
        if ~isempty(L)
            L = [L(1)-1,L]; % get rawfile from before sb(k)
            % grab the ltsa pwr matrix to plot
            PARAMS.ltsa.infile = fnames(K,:);
            read_ltsahead_GoM % get some stuff we'll need
            nbin = length(L) * PARAMS.ltsa.nave(L(1));    % number of time bins to get
            fid = fopen(fullfile(PARAMS.ltsa.inpath,PARAMS.ltsa.infile),'r');
            % samples to skip over in ltsa file
            skip = PARAMS.ltsa.byteloc(L(1));
            fseek(fid,skip,-1);    % skip over header + other data
            
            % LTSA session power vector
            pwr{k} = fread(fid,[PARAMS.ltsa.nf,nbin],'int8');   % read data
            fclose(fid);
            % make time vector
            t1 = rfTimeStart{K}(L);
            t2 = rfTimeEnd{K}(L);
            dt = datenum([0 0 0 0 0 5]);
            
            % LTSA session time vector
            % build time vector by concatonating times for each raw file 
            pt_temp = {};
            for iTT = 1:size(t1,2)
                pt_temp{iTT,1} = t1(iTT):dt:t2(iTT)-dt; 
            end
            pt{k} = horzcat(pt_temp{:});
            
        else
            rfT = rfTimeStart{K,:};
            disp('Missing raw file for this time ')
            disp(['bout start time is ',datestr(sb(k))])
            disp(['bout end time is ',datestr(eb(k))])
        end
    elseif isempty(K)   % use the end of one and the beginning of next ltsa
        disp('Session spans two LTSAs')
        disp(['bout start time is ',datestr(sb(k))])
        disp(['bout end time is ',datestr(eb(k))])
        
        Ks = find(sTime <= sb(k) & eTime >= sb(k));
        Ke = find(sTime <= eb(k) & eTime >= eb(k));
        if isempty(Ks) || isempty(Ke)
            disp('Missing raw file(s) for this bout')
            k = k+1;
            continue
        end
        
        Ls = find(rfTimeStart{Ks,:} >= sb(k));
        Le = find(rfTimeEnd{Ke,:} <= eb(k));
        if ~isempty(Ls)
            Ls = [Ls(1)-1,Ls]; % get rawfile from before sb(k)
            
            % grab the ltsa pwr matrix to plot
            PARAMS.ltsa.infile = fnames(Ks,:);
            read_ltsahead_GoM % get some stuff we'll need
            nbin = length(Ls) * PARAMS.ltsa.nave(Ls(1));    % number of time bins to get
            fid = fopen(fullfile(PARAMS.ltsa.inpath,PARAMS.ltsa.infile),'r');
            
            % samples to skip over in ltsa file
            skip = PARAMS.ltsa.byteloc(Ls(1));
            fseek(fid,skip,-1);    % skip over header + other data
            pwrLs = fread(fid,[PARAMS.ltsa.nf,nbin],'int8');   % read data
            fclose(fid);
            
            % make time vector
            t1 = rfTimeStart{Ks}(Ls(1));
            t2 = rfTimeEnd{K}(L);
            dt = datenum([0 0 0 0 0 5]);
            pt_temp = {};
            for iTT = 1:size(t1,2)
                pt_temp{iTT,1} = t1(iTT):dt:t2(iTT)-dt; 
            end
            ptLs = horzcat(pt_temp{:});
        end
        if ~isempty(Le)
            
            % grab the ltsa pwr matrix to plot
            PARAMS.ltsa.infile = fnames(Ke,:);
            read_ltsahead_GoM % get some stuff we'll need
            nbin = length(Le) * PARAMS.ltsa.nave(Le(1));    % number of time bins to get
            fid = fopen(fullfile(PARAMS.ltsa.inpath,PARAMS.ltsa.infile),'r');
            
            % samples to skip over in ltsa file
            skip = PARAMS.ltsa.byteloc(Le(1));
            fseek(fid,skip,-1);    % skip over header + other data
            pwrLe = fread(fid,[PARAMS.ltsa.nf,nbin],'int8');   % read data
            fclose(fid);
            
            % make time vector
            t1 = rfTimeStart{K}(L(1));
            t2 = rfTimeEnd{K}(L);
            dt = datenum([0 0 0 0 0 5]);
            pt_temp = {};
            for iTT = 1:size(t1,2)
                pt_temp{iTT,1} = t1(iTT):dt:t2(iTT)-dt; 
            end
            ptLe = horzcat(pt_temp{:});
        end
        
        if isempty(Ls) || isempty(Le)
            disp('Rawfiles for this bout not found ')
            k = k + 1;
            continue
        else            % combine from end of ltsa with begin of next
            pwr{k} = [pwrLs pwrLe];
            pt{k} = [ptLs ptLe];
        end

    else
        disp(['K = ',num2str(K)])
                disp(['bout start time is ',datestr(sb(k))])
        disp(['bout end time is ',datestr(eb(k))])
    end
    
    disp(['Session: ',num2str(k),'  Start: ',datestr(sb(k)),'  End:',datestr(eb(k)),...
        '   Duration: ',num2str(bd(k)),' hrs'])
    
    k = k+1;
end
ltsaFreq = PARAMS.ltsa.f;
df = PARAMS.ltsa.dfreq;

% Save output for use in detEdit.
save(fnLTSA,'pwr','pt','bd','nb','eb','sb','gt','ltsaFreq','df','-v7.3')

disp(['Done with file ',fn])
tc = toc;
disp(['Elasped Time : ',num2str(tc),' s'])

