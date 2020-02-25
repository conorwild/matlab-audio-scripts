function r = normwavs(varargin)
% normwavs.m
% -------------------------------------------------------------------------
% Usage: Navigate to a directory that contains the .wav files you want to
% normalize.  Then run this script.  Easy!
%
% Arguments:
%   'fs'            Sample Frequency, defaults to 44100Hz
%
%   'idir'          Specify an alternate directory to scan for .wavs.
%                       Default is the current directory.
%
%   'odir'          Output directory, is added to the input directory path.
%                       Default is the input directory.
%
%   'filefilter'    Only normalize .wavs that begin with this string.
%                       Default is nothing, so normalize all .wavs
%
%   'prefix'        Add this string to the beginning all new files
%                       Default is 'norm'
%
%   'target'        The target average RMS (in dB) power of the files
%                       Defaults is -20dB
%
%   'dofades'       Put ramps at the start and end?
%                       Default is 0 (no)
%
%   'ramplength'    The length of the ramps, if you choose to use them.
%                       Default is 10ms (0.01)
%
% -------------------------------------------------------------------------
%
% Example:  Normalize all the .wav files that begin with "1_" in c:\mywavs,
% to have an average RMS power of -35dB, then save them all in
% "c:\mywavs\set1norm".
%
%   cd('c:\mywavs');
%   normwavs('odir', 'set1norm', 'filefilter', '1_', 'target', -35);
%
% -------------------------------------------------------------------------
%       cwild 15/12/2009


% Set the defaults arguments
vdefaults = {'fs', 44100, [], ...
    'idir', pwd, {}, ...               %Read files from this directory
    'odir', '', {}, ...                %Write files to idir\\this directory
    'filefilter', '', {}, ...          %Read only files that begin with this
    'prefix', 'norm', {}, ...};        %Normalize RMS power of each band?  (i.e. "whiten")
    'target', -20, [], ...
    'dofades', 1, [0 1], ...
    'ramplength', 0.01, [], ...
    'trimStart', 0, [0 1], ...
    'trimEnd', 0, [0 1], ...
    'trimThreshDB', -40, [], };

vargs = vargParser(varargin, vdefaults);


vargs.target = 10^(vargs.target/20);

fprintf('Normalizing to %d dB\n\n', vargs.target);

outDir = fullfile(pwd, vargs.odir)
createDirectory(outDir, 0);

% Go to the directory with the .wav files
wavDir = vargs.idir;    % get the directory name
cd(wavDir);             % go there

% List all the .wav files in the directory
wavFiles = dir(sprintf('%s*.wav', vargs.filefilter));
disp(sprintf('Reading From: %s (%d files found)', wavDir, length(wavFiles)));

% Read each .wav file and get its avg RMS power
for file = 1 : length(wavFiles)
    thisFile = wavFiles(file).name; % Actually get the filename
    [y,fs,nBits,opts] = wavread(thisFile);
    if fs ~= vargs.fs
        error(sprintf('NVS Error: %s has sample rate of %dHz (should be %dHz)', thisFile, fs, vargs.fs));
    end

    % Record the RMS power of each file
    for channel = 1 : size(y,2)   %For each channel of the source
        rms = sqrt(mean(y(:,channel).^2));
        y(:,channel) = y(:, channel)* vargs.target/rms;
    end

    if vargs.trimStart
       
        nsamples = round(vargs.fs*vargs.ramplength);  % # of samples for the ramp
        threshold = 10^(vargs.trimThreshDB/20);
        sampleI = find(y(:,1) > threshold);
        
        y = y(max((sampleI(1)-nsamples),1):end, :);     
    end
    
    
    if vargs.dofades
        nsamples = round(vargs.fs*vargs.ramplength);  % # of samples for the ramp

        %Ramp in
        ramp = [ 0 : 1/(nsamples-1) : 1 ]';
        y(1:nsamples,:) = y(1:nsamples,:).*ramp;

        %Ramp out
        ramp = flipud(ramp);
        y(length(y)-(nsamples-1):length(y),:) = y(length(y)-(nsamples-1):length(y),:).*ramp;
    end


    wavwrite(y, fs, nBits, fullfile(outDir, sprintf('%s%s', vargs.prefix, thisFile)));
    

end % end file





disp('DONE');
r = 0;
end