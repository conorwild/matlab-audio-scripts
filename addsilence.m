function r = addsilence(timeMS, varargin)

%This script adds silence to the end of some .wav files, specified in
%milliseconds

% Set the defaults arguments
vdefaults = {'fs', 44100, [], ...
    'idir', pwd, {}, ...               %Read files from this directory
    'odir', '', {}, ...                %Write files to idir\\this directory
    'filefilter', '', {} };

vargs = vargParser(varargin, vdefaults);

outDir = fullfile(pwd, vargs.odir)
createDirectory(outDir, 0);

wavDir = vargs.idir;
cd(wavDir);

wavFiles = dir(sprintf('%s*.wav', vargs.filefilter));
disp(sprintf('Reading From: %s (%d files found)', wavDir, length(wavFiles)));

nsamples = vargs.fs * timeMS / 1000;

% Read each .wav file and get its avg RMS power
for file = 1 : length(wavFiles)
    thisFile = wavFiles(file).name;
    [y,fs,nBits,opts] = wavread(thisFile);
    if fs ~= vargs.fs
        error(sprintf('NVS Error: %s has sample rate of %dHz (should be %dHz)', thisFile, fs, vargs.fs));
    end

    y = [y; zeros(nsamples,1)];
   
    wavwrite(y, fs, nBits, fullfile(outDir, sprintf('%s', thisFile)));

end % end file

disp('DONE');
r = 0;
end