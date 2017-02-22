function [decoded_data, preFEC] = decode_maher(dvb,soft_data,EsNo)
%{
Picks nearest standard code to puncture.

Input:  dvb = structure with all the coding parameters including H matrix,
              use_bch and use_interleaver
        soft_data = complex valued vector of an integer number of frames
        EsNo= OSNR*2*Bref/Rs

Output: 
        decoded_data = logical array
        preFEC decoded data (optional)

%}

% Bref=12.5e6;12.5e6; %GHz
% Rs=25e6; %GBd
% OSNR=10.^(OSNRdB./10);
% EsNo=OSNR*2*Bref/Rs;
%% Set up variables
NoiseVar=1./EsNo;

num_frames = size(soft_data,1)*dvb.BitsPerSymbol/dvb.LDPCCodewordLength;
use_bch = dvb.use_bch
use_interleaver = dvb.use_interleaver

if(use_bch)
    num_infobits = dvb.BCHMessageLength
else
    num_infobits = dvb.BCHCodewordLength
end
size_ldpc_codeword=dvb.LDPCCodewordLength;
symbols_per_frame=size_ldpc_codeword/dvb.BitsPerSymbol;
% infobits=sent(1:num_infobits)';
% infobits=infobits>0;
     


%% Create decoder objects
hDemodQAM = comm.RectangularQAMDemodulator('ModulationOrder',2^dvb.BitsPerSymbol,...
    'BitOutput', true, ...
    'PhaseOffset', 0, ...
...%     'SymbolMapping', 'Custom', ...
...%     'CustomSymbolMapping', symb_mapQAM, ... adjust since Symbol Mapping will differ
    'DecisionMethod', 'Approximate log-likelihood ratio', ...
    'Variance', NoiseVar);


hLDPCDec = comm.LDPCDecoder(dvb.LDPCParityCheckMatrix, ...
    'IterationTerminationCondition', 'Parity check satisfied', ...
    'MaximumIterationCount',         dvb.LDPCNumIterations, ...
    'NumIterationsOutputPort',       true);
% ,...
%     'FinalParityChecksOutputPort', true,...
%     'DecisionMethod','Soft decision',...
%     'OutputValue','Whole codeword');

hDeintrlv = comm.BlockDeinterleaver(dvb.InterleaveOrder);

hBCHDec = comm.BCHDecoder('CodewordLength', dvb.BCHCodewordLength, ...
    'MessageLength', dvb.BCHMessageLength, ...
    'PrimitivePolynomialSource', 'Property', ...
    'PrimitivePolynomial', dvb.BCHPrimitivePoly, ...
    'GeneratorPolynomialSource', 'Property', ...
    'GeneratorPolynomial', dvb.BCHGeneratorPoly, ...
    'CheckGeneratorPolynomial', false);



%% Iterate over frames and decode
decoded_data = zeros(num_frames,num_infobits)>0;
% wrong_bits=0;
% preFEC_wrong_bits=0;
numIters=zeros(num_frames,1);

for j=1:num_frames
    demodOut5           = step(hDemodQAM,    soft_data((j-1)*symbols_per_frame+1:j*symbols_per_frame));
    preFEC              = demodOut5<0; 
    if use_interleaver
        deintrlvrOut       = step(hDeintrlv, demodOut5(1:size_ldpc_codeword));
    else
        deintrlvrOut       = demodOut5(1:size_ldpc_codeword);
    end

    [ldpcDecOut, numIter] = step(hLDPCDec,  deintrlvrOut);
    
    if use_bch
        bchDecOut            = step(hBCHDec,   ldpcDecOut);
        decoded_data(j,:)            = bchDecOut(1:num_infobits,1) > 0;
    else
        decoded_data(j,:)            = ldpcDecOut(1:num_infobits,1) > 0;
    end
    
    numIters(j)=numIter;
end

end