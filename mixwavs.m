function r = mixwavs(targetDir, noiseDir, SNRdb, varargin)
% r = mixwavs.m(targetDir, noiseDir, SNRdb, varargin)
% -------------------------------------------------------------------------
% Usage: Navigate to a directory that contains two directories -- one that
% contains 'target' .wavs and one that contains 'distracter' .wavs.  Files
% will be mixed together such that the first file from the target directory
% will be added to the first file in the distractor directory at the
% specified SNR.  If your file mapping is not alphabetical, you can use a
% 'mapping file', and specify that in the optional arguments.
%
% Required Arguments:
%
%   targetDir:      a string that indicates the name of the directory with
%                   all your 'target' .wavs
%
%   noiseDir:       a string that indicates the name of the directory with
%                   all your 'distracter' .wavs
%
%   SNRdb:          the desired signal-to-noise ratio in DB
%
% Example: Mix the files in directory wavSet1 with those in the driectory
%               wavSet2 at a SNR of -32 dB.
%
%       mixwavs('wavSet1', 'wavSet2', -32);
%
% Optional Arguments:
%
%   'fs':           Sampling Frequency of your .wavs
%                       Default is 44100 Hz
%
%   'odir':         Output directory, is added to the input directory path.
%                       Default is the pwd\\'Mixed_<SNRdb>'.
%
%   'mappingFile':  If your mapping is not alpabetical (e.g. you want to
%                   mix the first file in the target directory with the 5th
%                   file in the distracter directory), you can use a text
%                   file with a line for every mapping.  In this file
%                   there should be two columns (separated by a tab), where
%                   the first column indicates the 'target' file, and the
%                   second column in the 'noise' file.  
%                       
%                   The mapping file has to be located in the directory
%                   that contains the two .wav directories.
%
%   'autoScale':    Automatically scale output to avoid clipping?
%
% -------------------------------------------------------------------------
%       cwild 11/01/2011
%

% Set the defaults arguments
vdefaults = { 'fs', 44100, [], ...
              'odir', sprintf('Mixed_%ddB', SNRdb), {}, ...
              'mappingFile', '', {}, ...
              'autoScale', 0, [0 1] };

vargs = vargParser(varargin, vdefaults);

targetDir = fullfile(pwd, targetDir);
noiseDir = fullfile(pwd, noiseDir);

targetFiles = dir( fullfile(targetDir, '*.wav'));
noiseFiles = dir( fullfile(noiseDir, '*.wav'));

outDirectory = fullfile(pwd, vargs.odir);
createDirectory(outDirectory, 0);

% Load the mapping file
if length(vargs.mappingFile) > 0
    fid = fopen(vargs.mappingFile, 'r');
    mapping = textscan(fid, '%s%s');
    
    % Or, create an alphabetical mapping
else
    assert(length(targetFiles)==length(noiseFiles));
    for f = 1 : length(targetFiles)
        targets{f} = targetFiles(f).name;
        noises{f} = noiseFiles(f).name;
    end
    mapping{1} = targets;
    mapping{2} = noises;
end

fprintf('\nFound %d mappings between Targets and Noises', length(mapping{1}));
fprintf('\n ->Found %d .wavs in the Target directory (%s)', length(targetFiles), targetDir);
fprintf('\n ->Found %d .wavs in the Noise directory (%s)', length(noiseFiles), targetDir);
fprintf('\n\nMixing .wavs to achieve a %d dB SNR', SNRdb);
if vargs.autoScale
    fprintf('\n ->We are auto-scaling the output to avoid clipping.\n\n');
end
fprintf('\n%100s', '');

for f = 1 : length(mapping{1})
    fprintf('%s%-100s', repmat(sprintf('\b'),1,100), sprintf('PROCESSING %d / %d (%s + %s)', f, length(mapping{1}), mapping{1}{f}, mapping{2}{f}));

    target = mapping{1}{f};
    noise = mapping{2}{f};
    
    if ~exist(fullfile(targetDir, mapping{1}{f}))
        error(sprintf('Error: Cannot find %s', fullfile(targetDir, mapping{1}{f})));
    elseif~exist(fullfile(noiseDir, mapping{2}{f}))
        error(sprintf('Error: Cannot find %s', fullfile(noiseDir, mapping{2}{f})));
    end
    
    % Open the two files
    [yTarget,fs,nBits,opts] = wavread( fullfile(targetDir, mapping{1}{f}) );
    [yNoise, fs,nBits,opts] = wavread( fullfile(noiseDir, mapping{2}{f}) );
    
    % Calculate the power of the target
    rmsT = sqrt(mean(yTarget(:).^2));
    rmsTdb = 20*log10(rmsT);
    
    % Same for the noise
    rmsN = sqrt(mean(yNoise(:).^2));
    rmsNdb = 20*log10(rmsN);
    
    SNR = 10^(SNRdb/20);
    if length(yTarget) < length(yNoise)
        yTarget = [yTarget; zeros(length(yNoise) - length(yTarget),1)];
    elseif length(yTarget) > length(yNoise)
        yNoise = [yNoise; zeros(length(yTarget) - length(yNoise),1)];
    end
    
    
    % What is the RMS power of the noise, based on the SNR and the RMS of the
    % target?
    diff = 10^((rmsTdb - SNRdb)/20);
    
    yNew = yTarget + yNoise .* diff/rmsN;
    
    if vargs.autoScale
        yNew = (yNew ./ max( abs([min(yNew) max(yNew)]))) .* 0.9;
    end
    
    tName = target(1:find(target=='.')-1);
    nName = noise(1:find(noise=='.')-1);
    
    wavwrite(yNew, fs, nBits, fullfile(outDirectory, sprintf('%s_%s_%ddB.wav', tName, nName, SNRdb)));
end

fprintf('\n\n DONE!\n');

end