function r = conver2Mono(varargin)
% conver2Mono.m
% -------------------------------------------------------------------------
% Usage: Navigate to a directory that contains the .wav files you want to
% convert.  Then run this script.  Easy!
%
% Arguments:
%   'channel'            Which channel do we use? L/R/average
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
%       cwild 2013-03-04


% Set the defaults arguments
vdefaults = { ...
    'channel', 'L', {'L','R','average'}, ...
    'idir', pwd, {}, ...
    'odir', '', {}, ...
    'fileFilter', '', {}, ...
    'prefix', '', {}, ...
    };

vargs = vargParser(varargin, vdefaults);


fprintf('Converting files to mono\n\n');

outDir = fullfile(pwd, vargs.odir)
createDirectory(outDir, 0);

% Go to the directory with the .wav files
wavDir = vargs.idir;    % get the directory name
cd(wavDir);             % go there

% List all the .wav files in the directory
wavFiles = dir(sprintf('%s*.wav', vargs.fileFilter));
disp(sprintf('Reading From: %s (%d files found)', wavDir, length(wavFiles)));

% Read each .wav file and get its avg RMS power
for file = 1 : length(wavFiles)
    thisFile = wavFiles(file).name; % Actually get the filename
    [y,fs,nBits,opts] = wavread(thisFile);
   
    if strcmp(vargs.channel, 'L')
        y = y(:,1);
    elseif strcmp(vargs.channel, 'R')
        y = y(:,2);
    elseif strcmp(vargs.channel, 'average')
        y = mean(y, 2);
    else
        error('Invalid option: %s', vargs.channel);
    end

    wavwrite(y, fs, nBits, fullfile(outDir, sprintf('%s%s', vargs.prefix, thisFile)));
    
end % end file

disp('DONE');
r = 0;

end