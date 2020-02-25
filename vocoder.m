function r = vocoder(bandEdges, varargin)

% r = vocoder(bandEdges, varargin)
%
% This is a vocoder. hooray!
%__________________________________________________________________________
%
% Returned Parameters
%
%       r       : some returned stuff
%
% Required Input Parameters
%
%       bandEdges : [1xN] band edges, specificed in frequency
%
% Optional Input Parameters
%
%       <parameter>, <default>, <allowed>
%
%       'fs', 44100, [], ...               %Sample rate of the files
%       'f0', 40, [], ...                  %Pulse rate (for Pulse Trains)
%       'order', 800, [], ...              %Order of the Hann Bandpass Filters
%       'plotfilters', 0, [0 1], ...       %Plot the filter transfer funtions?
%       'idir', pwd, {}, ...               %Read files from this directory
%       'odir', '', {}, ...                %Write files to idir\\this directory
%       'filefilter', '', {}, ...          %Read only files that begin with this
%       'prefix', 'PT_', {}, ...           %Prefix for output files
%       'carrier', 'pulse', {'pulse', 'white', 'pink', 'sinusoid', 'speech}, % WHAT KIND OF NOISE TO USE AS THE CARRIER?
%       'rotate', 0, [0 1], ...            %Spectrally rotate?
%       'reverse', 0, [0 1], ...           %Reverse in time?
%       'whiten', 1, [0 1];                %Normalize RMS power of each band?  (i.e. "whiten")
%       'compress', 1, []};                %Compress Envelopes in a ratio x:1
%
% Examples:
%   
%   1) vocode all .wav files in the current directory as single band speech shaped
%   noise, put them in a new directory with the prefix 'SSN'
%
%       vocoder( [50 8000], 'carrier', 'speech', 'odir', 'SpeechShaped', 'prefix', 'SSN_' );
%
%__________________________________________________________________________
%   cwild 05/01/2011 (m/d/y)

    % Set the defaults arguments
    vdefaults = {'fs', 44100, [], ...               %Sample rate of the files
                 'f0', 40, [], ...                  %Pulse rate
                 'order', 800, [], ...              %Order of the Hann Bandpass Filters
                 'plotfilters', 0, [0 1], ...       %Plot the filter transfer funtions?
                 'idir', pwd, {}, ...               %Read files from this directory
                 'odir', '', {}, ...                %Write files to idir\\this directory
                 'filefilter', '', {}, ...          %Read only files that begin with this
                 'prefix', 'PT_', {}, ...           %Prefix for output files
                 'carrier', 'pulse', {'pulse', 'white', 'pink', 'speech', 'sinusoid', 'speech'}, ...
                 'rotate', 0, [0 1], ...            %Spectrally rotate?
                 'reverse', 0, [0 1], ...           %Reverse in time?
                 'whiten', 1, [0 1], ...            %Normalize RMS power of each band?  (i.e. "whiten")
                 'compress', 1, []};             %Compress Envelopes in a ratio x:1

             
    vargs = vargParser(varargin, vdefaults);
    
    numBands = size(bandEdges, 2) - 1;
    fn = vargs.fs/2; 
    
    fDesc = '';
    for b = 1 : numBands + 1
        fDesc = sprintf('%s -> %dHz', fDesc, bandEdges(b));
    end
    fDesc = fDesc(5:length(fDesc));
    
    % Create our filter bank
    disp(sprintf('\nCreating %d Filters: %s\n', numBands, fDesc));
    
    fDesc = '';
    
    for b = 1 : numBands
        if bandEdges(b) == 0          % Low Pass
            fc = bandEdges(b+1) / fn;
            fType = 'low';
        elseif bandEdges(b+1) == fn   % High Pass
            fc = bandEdges(b)/ fn;
            fType = 'high';
        else                        % Band Pass
            fc = [bandEdges(b) bandEdges(b+1)] / fn;
            fType = 'bandpass';
        end
        h(b,:) = fir1(vargs.order, fc, fType, hann_c(vargs.order+1));
        fDesc = [fDesc sprintf('h(%d,:),1,',b)];
    end
    
    %Plot the filters?
    if vargs.plotfilters
        eval( sprintf('fvtool(%s, ''fs'', %d)', fDesc(1:length(fDesc)-1), vargs.fs) );
    end
    
    %Create our envelope filter
    [z, p, k] = butter(4, 30/fn, 'low');  % 4th Order Buttworth Lowpass 30Hz
    [sos , g] = zp2sos(z, p, k);
    eH = dfilt.df2sos(sos,g);

    % Get a list of wav files
    cd(vargs.idir);
    wavFiles = dir(sprintf('%s*.wav', vargs.filefilter));
    disp(sprintf('Reading From: %s (%d files found)', vargs.idir, length(wavFiles)));
    
    outDir = fullfile(vargs.idir, vargs.odir);
    if ~exist(vargs.odir, 'dir') && ~strcmp(vargs.odir, '')
        mkdir(outDir);
    end
    disp(sprintf('Writing To: %s\n', outDir));
    
    tic
    
    fprintf('%60s', '');
    % Now, for each wav file in the directory
    for file = 1 : length(wavFiles)
        
        clear cBands;
        
        thisFile = wavFiles(file).name;
        fprintf('%s%-60s', repmat(sprintf('\b'),1,60), sprintf('PROCESSING %d / %d', file, length(wavFiles)));

        [y,fs,nBits,opts] = wavread(thisFile);
        if fs ~= vargs.fs
            error(sprintf('NVS Error: %s has sample rate of %dHz (should be %dHz)', thisFile, fs, vargs.fs));
        end

        nChannels = size(y,2);
        
        % Generate the carrier
        tVector = [0 : 1/vargs.fs : (length(y)-1)/vargs.fs]; %Time vector
        c = zeros(size(tVector));
        switch vargs.carrier
            case 'pulse'
                numHarmonics = floor(bandEdges(end)/vargs.f0) - 1;
                for harm = 0 : numHarmonics
                    fH = vargs.f0 * (harm+1);      % the frequency of this harmonic
                    c = c + sin(2*pi*fH*tVector + mod(harm,2)*pi/2);
                end
            case 'white'
                c = randn(size(c));
            case 'pink'
                a = exp(-2*pi*bandEdges(1)/fs);    % de-emphasize 6DB/octave above low cutoff
                c = filter( 1, [1 -a], randn(size(c)));
            case 'speech'
                N = length(y);
                N2 = floor(N/2)-1;
                F = fft(y);                                     % Get the FFT of the signal
                A = abs(F);                                     % Get the amplitudes
                A2 = A(2:1+N2);                                 % Take the first half (symmetry woohoo!)
                P2 = 2*pi*(rand(N2,1)-0.5);                     % Generate random phases in the range -pi to +pi
                D2 = A2.*exp(i*P2);            
                F2 = [1; D2; 0; flipud(conj(D2))];

                c = ifft(F2)';                                  % Take the inverse FFT to get our carrier
                
                c = [c zeros(length(y)-length(c),1)];           % Pad with zeroes if needed
                
            otherwise
                error(sprintf('Invalid carrier type: %s', vargs.carrier));
        end
        
        % Create the modulated carrier bands
        for b = 1 : size(h,1)
            for j = 1 : size(y,2)   %For each channel of the source   
                yBand = filter(h(b,:), 1, y(:,j));     % Separate the source band        
                envelope = filter(eH, yBand .* (yBand>= 0)); %HW rectify and filter
                
                %envelope = compressor2(envelope, vargs.compress, 'plotsignals', vargs.plotfilters);
                %envelope = compressor(envelope, vargs.compress, 'threshtype', 'mean', 'timeconstant', 30, 'plotsignals', vargs.plotfilters);
               
                envelope = abs(envelope).^(1/vargs.compress);
                
                bandSelector = b;
                if vargs.rotate
                    bandSelector = numBands - b + 1;
                end

                % Apply the envelope to the harmonic complex  
                cBands(b,:,j) = filter(h(bandSelector,:),1, c) .* envelope';
                
                % Get the RMS power of this band
                rms(b,j) = sqrt(mean(cBands(b,:,j).^2));
            end
        end
        
        %Normalize the RMS Power of each band
        if vargs.whiten
            for b = 1 : numBands
                for j = 1 : size(y,2)
                    cBands(b,:,j) = cBands(b,:,j) * max(mean(rms))/rms(b,j);
                end
            end
        end
        
        if numBands > 1
            cm = sum(cBands); %add all the bands together
        else
            cm = cBands;
        end
        cm = reshape(cm(1,:,:), length(y), nChannels);
        
        if vargs.reverse
            cm = flipud(cm);
        end
           
        wavwrite(0.7 .* (cm ./ max(cm(:,1))), fs, nBits, fullfile(outDir, sprintf('%s%s', vargs.prefix, thisFile)));
    end
    disp('DONE');
    toc
r = 0
end

function v = hann_c(N)
    v = 0.5*(1-cos(2*pi*[0:N-1]/(N-1)))';
end