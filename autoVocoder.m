function r = autoVocoder(numBands, filefilter)
    flo = 50;
    fhi = 20000;
    xlo = Greenwood_FrToX(flo);
    xhi = Greenwood_FrToX(fhi);
    dx = (xhi-xlo)/numBands;
    
    bandEdges = [];
    for i = 0 : numBands
        bandEdges = [bandEdges Greenwood_xToF(xlo+i*dx)];
    end
    
    vocoder(bandEdges, 'whiten', 1, 'carrier', 'white', 'filefilter', filefilter, 'prefix', sprintf('NV_%03d_', numBands));
    
    
end