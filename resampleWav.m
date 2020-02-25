function y2 = resampleWav(y1, Fs1, Fs2)
% This function resample the data y (obtained with Fs1), to the new
% sampling frequency specified by Fs2.  It makes use of the interp1 command
% cwild 2013-03-04

% length of y1 in seconds
t1 = length(y1)/Fs1;

% interpolate
y2 = interp1( 1/Fs1:1/Fs1:t1, y1, 1/Fs2:1/Fs2:t1, 'cubic', 'extrap');

y2 = y2';

end