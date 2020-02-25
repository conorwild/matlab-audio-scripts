function r = extractEnvelope(y, fs, varargin)

fn = fs/2;

% Envelope filter...
[z, p, k] = butter(4, 30/fn, 'low');    % 4th Order Buttworth Lowpass 30Hz
[sos , g] = zp2sos(z, p, k);
eH = dfilt.df2sos(sos,g);

envelope = filter(eH, y .* (y >= 0));   % HW rectify and filter
envelope = envelope ./ max(envelope);   % Range 0 -> 1

r = envelope;

end
