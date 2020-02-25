function r = trimWavs(varargin)

% Set the defaults arguments
vdefaults = { ...
    'iDir', pwd, {}, ...	%Read files from this directory
    'oDir', 'trimmed', {}, ...                      %Write files to idir\\this directory
    'fileFilter', '', {}, ...                       %Read only files that begin with this
    'fs', 44100, [], ...                            %Expected sampling frequency
    'prefix', 'trim_', {}, ...
    'silenceDuration', 0.5, [], ...
    'silenceThresholdDB', -45, [], ...
    'rampLengthSecs', 0.01, [], ...  
    };

vargs = vargParser(varargin, vdefaults);

outDir = fullfile(pwd, vargs.oDir)
createDirectory(outDir, 0);

% List all the .wav files in the directory
wavFiles = dir(fullfile(vargs.iDir, sprintf('%s*.wav', vargs.fileFilter)));
numFiles = length(wavFiles);
disp(sprintf('Reading From: %s (%d files found)', vargs.iDir, numFiles));

% ------------------------------------------------------------------------
% First thing's first: Let's trim all the original recordings so they have
% the same amount of silence at the start / end.  THis will be useful when
% we normalize the durations of all sounds. Let's also record RMS Power 
% and durations

silenceThresholdDB = -45;                                   % silence threshold in DB
silenceThreshold = 10^(silenceThresholdDB/20);              % convert threshold in dB to intensity value                                                % duration of ramps in seconds
numSamplesPerRamp = round(vargs.fs*vargs.rampLengthSecs);         % # of samples for the ramp
numSamplesSilence = round(vargs.fs*vargs.silenceDuration);

% We have to store the trimmed files somewhere...
trimDir = fullfile(vargs.iDir, 'trimmed');  
trimFiles = [];
if ~exist(trimDir)
    mkdir(trimDir);
end

RMS = zeros(numFiles, 1);   % Here we shall store the RMS power of the sounds!
durs = zeros(numFiles, 1);  % And here we shall make note of their durations!  Huzzah!~ 

for file = 1 : length(wavFiles)
    
    % Read in the .wav file of the original recording
    thisFile = wavFiles(file).name;
    [y fs nb] = wavread(fullfile(vargs.iDir, thisFile));
    
    % Double checking the sampling frequency of the stimuli
    if fs ~= vargs.fs
        error('Sampling frequency of %s is %d, NOT %d.', thisFile, fs, vargs.fs); 
    end
    
    % Check / convert to mono
    if size(y, 2) > 1
        warning('%s has %d channels, I''m converting that shit to mono!', thisFile, size(y, 2));
        y = mean(y, 2);
    end

    numSamples = length(y);
    sampleI = find(abs(y(:, 1)) > silenceThreshold);        % samples in the .wav that are > threshold
    firstI = min(sampleI);                                  % first sample in the waveform over the threshold
    lastI = max(sampleI);                                   % last sample in teh waveform over the threshold
    
    % Just in case we need to pad zeros for ramps...
    padStart = numSamplesPerRamp - firstI;
    padEnd = numSamplesPerRamp - (numSamples - lastI);
    
    % snip the file to include everything above the threshold, pad zeros
    % for ramps, if needed
    y = [zeros(padStart, 1); y(max(firstI-numSamplesPerRamp,1) : min(lastI+numSamplesPerRamp, numSamples)); zeros(padEnd, 1)];

    % Now add ramps
    y(1:numSamplesPerRamp) = y(1:numSamplesPerRamp) .* [0 : 1/numSamplesPerRamp : (1-1/numSamplesPerRamp)]';
    y(end-numSamplesPerRamp+1:end) =  y(end-numSamplesPerRamp+1:end) .* [(1-1/numSamplesPerRamp) : -1/numSamplesPerRamp : 0]';
    
    % Now pad with zeros to add silence to the start/end
    y = [zeros(numSamplesSilence-numSamplesPerRamp,1); y; zeros(numSamplesSilence-numSamplesPerRamp,1)];
    
    trimFile = fullfile(trimDir, [vargs.prefix thisFile]);
    trimFiles = strvcat(trimFiles, trimFile);   % add the new file to the list of newly trimmed files
    wavwrite(y, fs, nb, trimFile);              % Save it to disk

    % Get the duration of the newly trimmed file
    durs(file) = length(y) / fs;
    
    % Calculate the RMS power of the signal
    RMS(file) = sqrt(mean(y(:, 1).^2));
    
    % Ramps will be added during the normalization stage!  We have only
    % just included room for them at the moment.
    
end
end