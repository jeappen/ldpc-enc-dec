function dvb = getParamsDVBS2Demo_modified(subsystemType, EsNodB, ...
    numLDPCDecIterations)
% Modified to allow very high order constellations.
%getParamsDVBS2Demo DVB-S.2 link parameters
%   DVB = getParamsDVBS2Demo(TYPE, ESN0, NUMITER) returns DVB-S.2 link
%   parameters for subsystem type, TYPE, energy per symbol to noise power
%   spectral density ratio in dB, ESN0, and number of LDPC decoder
%   iterations, NUMITER. The output, DVB, is a structure with fields
%   specifying the parameter name and value.

% Copyright 2010-2011 The MathWorks, Inc.

validatestring(subsystemType, {'BPSK 1/4', ...
            'BPSK 1/3', 'BPSK 2/5', 'BPSK 1/2', 'BPSK 3/5', 'BPSK 2/3', ...
            'BPSK 3/4', 'BPSK 4/5', 'BPSK 5/6', 'BPSK 8/9', 'BPSK 9/10',...
            'QPSK 1/4', ...
            'QPSK 1/3', 'QPSK 2/5', 'QPSK 1/2', 'QPSK 3/5', 'QPSK 2/3', ...
            'QPSK 3/4', 'QPSK 4/5', 'QPSK 5/6', 'QPSK 8/9', 'QPSK 9/10',...
            '16QM 1/4', ...
            '16QM 1/3', '16QM 2/5', '16QM 1/2', '16QM 3/5', '16QM 2/3', ...
            '16QM 3/4', '16QM 4/5', '16QM 5/6', '16QM 8/9', '16QM 9/10',...
            '64QM 1/4', ...
            '64QM 1/3', '64QM 2/5', '64QM 1/2', '64QM 3/5', '64QM 2/3', ...
            '64QM 3/4', '64QM 4/5', '64QM 5/6', '64QM 8/9', '64QM 9/10',...
            '256Q 1/4', ...
            '256Q 1/3', '256Q 2/5', '256Q 1/2', '256Q 3/5', '256Q 2/3', ...
            '256Q 3/4', '256Q 4/5', '256Q 5/6', '256Q 8/9', '256Q 9/10',...
            '1kQM 1/4', ...
            '1kQM 1/3', '1kQM 2/5', '1kQM 1/2', '1kQM 3/5', '1kQM 2/3', ...
            '1kQM 3/4', '1kQM 4/5', '1kQM 5/6', '1kQM 8/9', '1kQM 9/10',...
            '4kQM 1/4', ...
            '4kQM 1/3', '4kQM 2/5', '4kQM 1/2', '4kQM 3/5', '4kQM 2/3', ...
            '4kQM 3/4', '4kQM 4/5', '4kQM 5/6', '4kQM 8/9', '4kQM 9/10',...
            '16kQ 1/4', ...
            '16kQ 1/3', '16kQ 2/5', '16kQ 1/2', '16kQ 3/5', '16kQ 2/3', ...
            '16kQ 3/4', '16kQ 4/5', '16kQ 5/6', '16kQ 8/9', '16kQ 9/10',...
            '8PSK 3/5', '8PSK 4/5', '8PSK 2/3', '8PSK 3/4', '8PSK 5/6', ...
            '8PSK 8/9', '8PSK 9/10'}, 'getParamsDVBS2Demo', 'TYPE', 1);
        
validateattributes(EsNodB, {'numeric'}, ...
    {'finite', 'scalar'}, 'getParamsDVBS2Demo', 'ESNO', 2);

validateattributes(numLDPCDecIterations, {'numeric'}, ...
    {'positive', 'integer', 'scalar'}, 'getParamsDVBS2Demo', 'NUMITER', 3);

modulationType = subsystemType(1:4);
codeRate = str2num(subsystemType(6:end)); %#ok<ST2NM>

dvb.EsNodB = EsNodB;
dvb.ModulationType = modulationType;

%--------------------------------------------------------------------------
% Source

dvb.NumBytesPerPacket = 188;
byteSize = 8;
dvb.NumBitsPerPacket = dvb.NumBytesPerPacket * byteSize;

%--------------------------------------------------------------------------
% BCH coding

[dvb.BCHCodewordLength, ...
 dvb.BCHMessageLength, ...
 dvb.BCHGeneratorPoly] = getbchparameters(codeRate);
dvb.BCHPrimitivePoly = de2bi(65581, 'left-msb');
dvb.NumPacketsPerBBFrame =floor(dvb.BCHMessageLength/dvb.NumBitsPerPacket);
dvb.NumInfoBitsPerCodeword = dvb.NumPacketsPerBBFrame*dvb.NumBitsPerPacket;
dvb.BitPeriod = 1/dvb.NumInfoBitsPerCodeword;

%--------------------------------------------------------------------------
% LDPC coding

dvb.LDPCCodewordLength = 64800;
dvb.LDPCParityCheckMatrix = dvbs2ldpc(codeRate);
if isempty(numLDPCDecIterations)
    dvb.LDPCNumIterations = 50;
else
    dvb.LDPCNumIterations = numLDPCDecIterations;
end

%--------------------------------------------------------------------------
% Interleaver: Section 5.3.3, p. 23

% No interleaving (for BPSK and QPSK)
dvb.InterleaveOrder = (1:dvb.LDPCCodewordLength).';
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

%--------------------------------------------------------------------------
% Modulation

switch modulationType
    case 'BPSK'
        Ry = [+1; -1];
        dvb.Constellation = complex(Ry);
        dvb.SymbolMapping = [0 1];
        dvb.PhaseOffset = 0;
        warning(message('comm:getParamsDVBS2Demo:InvalidModulationType')); 
    case 'QPSK'
        m=4;
        Ry = [+1; +1; -1; -1];
        Iy = [+1; -1; +1; -1];
        dvb.Constellation = (Ry + 1i*Iy)/sqrt(2);
        dvb.SymbolMapping = [0 2 3 1];
        dvb.PhaseOffset = pi/4; %note pi/4 by default for PSK modulator;
        dvb.Xij=repmat(dvb.Constellation,1,m)-repmat(dvb.Constellation.',m,1);
    case '8PSK'
        m=8;
        A = sqrt(1/2);
        Ry = [+A +1 -1 -A  0 +A -A  0].';
        Iy = [+A  0  0 -A  1 -A +A -1].';
        dvb.Constellation = (Ry + 1i*Iy);
        dvb.SymbolMapping  = [1 0 4 6 2 3 7 5];
        dvb.PhaseOffset = 0;
        dvb.Xij=repmat(dvb.Constellation,1,m)-repmat(dvb.Constellation.',m,1);
    case '16QM'
        m=16;
        x = (0:m-1)';
        dvb.Constellation = (qammod(x, m, 0, 'gray'))/sqrt(2*(m-1)/3);
        dvb.SymbolMapping  = 0:m-1;
        dvb.PhaseOffset = 0;
        dvb.Xij=repmat(dvb.Constellation,1,m)-repmat(dvb.Constellation.',m,1);
    case '64QM'
        m=64;
        x = (0:m-1)';
        dvb.Constellation = qammod(x, m, 0, 'gray')/sqrt(2*(m-1)/3);
        dvb.SymbolMapping  = 0:m-1;
        dvb.PhaseOffset = 0;
        dvb.Xij=repmat(dvb.Constellation,1,m)-repmat(dvb.Constellation.',m,1);
    case '256Q'
        m=256;
        x = (0:m-1)';
        dvb.Constellation = qammod(x, m, 0, 'gray')/sqrt(2*(m-1)/3);
        dvb.SymbolMapping  = 0:m-1;
        dvb.PhaseOffset = 0;
        dvb.Xij=repmat(dvb.Constellation,1,m)-repmat(dvb.Constellation.',m,1);
    case '1kQM'
        m=1024;
        x = (0:m-1)';
        dvb.Constellation = qammod(x, m, 0, 'gray')/sqrt(2*(m-1)/3);
        dvb.SymbolMapping  = 0:m-1;
        dvb.PhaseOffset = 0;
        dvb.Xij=repmat(dvb.Constellation,1,m)-repmat(dvb.Constellation.',m,1);        
    case '4kQM'
        m=4096;
        x = (0:m-1)';
        dvb.Constellation = qammod(x, m, 0, 'gray')/sqrt(2*(m-1)/3);
        dvb.SymbolMapping  = 0:m-1;
        dvb.PhaseOffset = 0;
        dvb.Xij=repmat(dvb.Constellation,1,m)-repmat(dvb.Constellation.',m,1);
    case '16kQ'
        m=16384;
        x = (0:m-1)';
        dvb.Constellation = qammod(x, m, 0, 'gray')/sqrt(2*(m-1)/3);
        dvb.SymbolMapping  = 0:m-1;
        dvb.PhaseOffset = 0;
        dvb.Xij=repmat(dvb.Constellation,1,m)-repmat(dvb.Constellation.',m,1);
    otherwise
        error(message('comm:getParamsDVBS2Demo:ModulationUnsupported'));
end

numModLevels = length(dvb.Constellation);
dvb.BitsPerSymbol = log2(numModLevels);

%--------------------------------------------------------------------------
% Complex scrambling sequence

dvb.SequenceIndex = 2;

%--------------------------------------------------------------------------
% Number of symbols per codeword

dvb.NumSymsPerCodeword = dvb.LDPCCodewordLength/dvb.BitsPerSymbol;

%--------------------------------------------------------------------------
% Noise variance for channel and estimate for LDPC coding

dvb.NoiseVar  = 1/(10^(dvb.EsNodB/10));
dvb.NoiseVarEst = dvb.NoiseVar/(2*sin(pi/numModLevels)); 
% Note that NoiseVarEst for QPSK is NoiseVar/(2*sqrt(2))

%--------------------------------------------------------------------------
% Delays

dvb.RecDelayPreBCH = dvb.BCHMessageLength;

%--------------------------------------------------------------------------
function [nBCH, kBCH, genBCH] = getbchparameters(R)

table5a = [1/4 16008 16200 12 64800 
           1/3 21408 21600 12 64800 
           2/5 25728 25920 12 64800
           1/2 32208 32400 12 64800
           3/5 38688 38880 12 64800
           2/3 43040 43200 10 64800
           3/4 48408 48600 12 64800
           4/5 51648 51840 12 64800
           5/6 53840 54000 10 64800
           8/9  57472 57600 8 64800
           9/10 58192 58320 8 64800];

rowidx = find(abs(table5a(:,1)-R)<.001);
kBCH = table5a(rowidx,2);
nBCH = table5a(rowidx,3);
tBCH = table5a(rowidx,4);

a8 = [1  0  0  0  1  1  1  0  0  0  0  0  0  0  1 ...
    1  1  0  0  1  0  0  1  0  1  0  1  0  1  1 ...
    1  1  1  0  1  1  1  0  0  0  1  0  0  1  0 ...
    0  1  1  1  1  0  0  1  0  1  1  1  1  0  1 ...
    1  1  1  0  1  0  0  0  1  1  0  0  1  1  1 ...
    1  1  1  1  0  0  0  1  1  0  1  1  0  1  0 ...
    1  1  1  0  1  0  1  0  0  0  0  0  1  0  0 ...
    1  1  1  1  1  0  0  1  0  1  1  0  0  1  1 ...
    0  0  0  1  0  1  0  1  1];

a10 = [1  0  1  1  0  0  0  0  0  0  0  0  1  0  1 ...
    0  1  0  0  0  0  1  1  0  0  1  1  1  0  1 ...
    1  0  1  1  1  1  1  1  1  0  0  0  0  1  0 ...
    1  0  1  0  0  0  1  1  0  0  1  1  0  0  0 ...
    1  1  1  1  1  0  1  1  0  1  0  1  0  0  1 ...
    1  1  1  0  0  0  0  1  0  1  0  1  1  1  0 ...
    0  0  0  0  0  1  1  1  1  1  0  1  1  1  1 ...
    1  1  0  1  0  0  0  1  0  0  1  0  0  0  1 ...
    1  0  0  0  0  0  0  0  1  1  0  1  1  1  0 ...
    0  0  1  0  1  1  1  0  1  1  0  1  1  0  0 ...
    1  0  1  1  0  0  1  0  0  0  1];

a12 = [1  0  1  0  0  1  1  1  0  0  0  1  0  0  1 ...
    1  0  0  0  0  0  1  1  1  0  1  0  0  0  0 ...
    0  1  1  1  0  0  0  0  1  0  0  0  1  0  1 ...
    1  1  0  0  0  1  0  1  0  0  0  1  0  0  0 ...
    1  1  1  0  0  0  1  0  1  0  0  0  0  1  1 ...
    0  0  1  1  1  1  0  0  1  0  1  1  0  0  1 ...
    1  0  1  1  0  0  0  1  1  0  1  1  1  0  0 ...
    0  0  1  1  0  1  0  1  0  0  0  0  1  0  0 ...
    0  1  0  0  0  1  0  0  1  0  0  0  0  0  0 ...
    1  1  0  1  0  0  0  1  1  1  1  0  0  0  0 ...
    1  0  1  1  1  1  1  0  1  1  1  0  1  1  0 ...
    0  1  1  0  0  0  0  0  0  0  1  0  0  1  0 ...
    1  0  1  0  1  1  1  1  0  0  1  1  1];

switch tBCH
case 8
    genBCH = a8;
case 10
    genBCH = a10;
case 12
    genBCH = a12;
end
