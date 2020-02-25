function r = generateSSN(y)

N = length(y);
N2 = floor(N/2)-1;
F = fft(y);                                     % Get the FFT of the signal
A = abs(F);                                     % Get the amplitudes
A2 = A(2:1+N2);                                 % Take the first half (symmetry!)
P2 = 2*pi*(rand(N2,1)-0.5);                     % Generate random phases in the range -pi to +pi
D2 = A2.*exp(i*P2);
F2 = [1; D2; 0; flipud(conj(D2))];
c = ifft(F2)';                                  % Take the inverse FFT to get our carrier
c = [c zeros(length(y)-length(c),1)];           % Pad with zeroes if needed

r = c;
end