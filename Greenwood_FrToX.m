function x = Greenwood_FrToX(frequency)
% Returns the  position 'x' on the basilar membrane of a certain frequency
% according to Greenwood's equation.
%
% Greenwood, D. D. (1990). A cochlear frequency-position function for several
% species---29 years later. The Journal of the Acoustical Society of America,
% 87(6), 2592–2605. https://doi.org/10.1121/1.399052
%
%   F = A(10^(ax) - k)
%   For humans:  A = 165, a = 2.1 (for x as a proportion), k = 1
%   50Hz occurs at x = 0.0547, 8kHz occurs at x = 0.8069
    x = (log10 ( (frequency/165)+1) ) / 2.1;
end
