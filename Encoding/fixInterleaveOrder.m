
if isequal(modulationType, 'QPSK') %interleaving not working with puncturing...hence QPShK
    Ncol = 2;
    iTemp = reshape(dvb.InterleaveOrder, ...
        dvb.LDPCCodewordLength/Ncol, Ncol).';
    if codeRate == 3/5
        % Special Case - Figure 8
        iTemp = flipud(iTemp);
    end
    dvb.InterleaveOrder = iTemp(:);
end

if isequal(modulationType, '8PSK')
    Ncol = 3;
    iTemp = reshape(dvb.InterleaveOrder, ...
        dvb.LDPCCodewordLength/Ncol, Ncol).';
    if codeRate == 3/5
        % Special Case - Figure 8
        iTemp = flipud(iTemp);
    end
    dvb.InterleaveOrder = iTemp(:);
end
if isequal(modulationType, '16QM')
    Ncol = 4;
    iTemp = reshape(dvb.InterleaveOrder, ...
        dvb.LDPCCodewordLength/Ncol, Ncol).';
    if codeRate == 3/5
        % Special Case - Figure 8
        iTemp = flipud(iTemp);
    end
    dvb.InterleaveOrder = iTemp(:);
end
if isequal(modulationType, '64QM')
    Ncol = 6;
    iTemp = reshape(dvb.InterleaveOrder, ...
        dvb.LDPCCodewordLength/Ncol, Ncol).';
    if codeRate == 3/5
        % Special Case - Figure 8
        iTemp = flipud(iTemp);
    end
    dvb.InterleaveOrder = iTemp(:);
end
if isequal(modulationType, '256Q')
    Ncol = 8;
    iTemp = reshape(dvb.InterleaveOrder, ...
        dvb.LDPCCodewordLength/Ncol, Ncol).';
    if codeRate == 3/5
        % Special Case - Figure 8
        iTemp = flipud(iTemp);
    end
    dvb.InterleaveOrder = iTemp(:);
end
if isequal(modulationType, '1kQM')
    Ncol = 10;
    iTemp = reshape(dvb.InterleaveOrder, ...
        dvb.LDPCCodewordLength/Ncol, Ncol).';
    if codeRate == 3/5
        % Special Case - Figure 8
        iTemp = flipud(iTemp);
    end
    dvb.InterleaveOrder = iTemp(:);
end
if isequal(modulationType, '4kQM')
    Ncol = 12;
    iTemp = reshape(dvb.InterleaveOrder, ...
        dvb.LDPCCodewordLength/Ncol, Ncol).';
    if codeRate == 3/5
        % Special Case - Figure 8
        iTemp = flipud(iTemp);
    end
    dvb.InterleaveOrder = iTemp(:);
end
if isequal(modulationType, '16kQ')
    Ncol = 16;
    iTemp = reshape(dvb.InterleaveOrder, ...
        dvb.LDPCCodewordLength/Ncol, Ncol).';
    if codeRate == 3/5
        % Special Case - Figure 8
        iTemp = flipud(iTemp);
    end
    dvb.InterleaveOrder = iTemp(:);
end