snr=0.5;%Energy per symbol by No
numF=10;
needed_coderate=1/2;0.9;5/6;1/2;

starting_coderate=0.85;
ending_coderate=0.56;
stepsize=0.02;

extra_coderates=[0.8]; %coderates not in starting_coderate:-stepsize:ending_coderate

needed_coderates=fliplr(union(starting_coderate:-stepsize:ending_coderate,extra_coderates)); %in descending order

needed_coderate=needed_coderates(1);

subsystemType_code='16QM'; %QPSK 16QM 64QM 256Q
existingDBVs=[] ;


%% DVB-S.2 Link, Including LDPC Coding
% This example shows the application of low density parity check (LDPC)
% codes in the second generation Digital Video Broadcasting standard
% (DVB-S.2), which is deployed by DIRECTV in the United States. The example
% uses communications System objects to simulate a transmitter-receiver
% chain that includes LDPC encoding and decoding.

% Copyright 2010-2015 The MathWorks, Inc.

%% Introduction
% The ETSI (European Telecommunications Standards Institute) EN 302 307
% standard for Broadcasting, Interactive Services, News Gathering and other
% broadband satellite applications (DVB-S.2) [ <#12 1> ] uses a
% state-of-the-art coding scheme to increase the channel capacity. The
% concatenation of LDPC (Low-Density Parity-Check) and BCH codes is the
% basis of this coding scheme.  LDPC codes, invented by Gallager in his
% seminal doctoral thesis in 1960, can achieve extremely low error rates
% near channel capacity by using a low-complexity iterative decoding
% algorithm [ <#12 2> ]. The outer BCH codes are used to correct sporadic
% errors made by the LDPC decoder.
%
% The channel codes for DVB-S.2 provide a significant capacity gain over
% DVB-S under the same transmission conditions. Depending on the
% transmission mode, DVB-S.2 provides Quasi-Error-Free operation (packet
% error rate below 10^ -7) at about 0.7 dB to 1 dB from the Shannon limit.
%
% This example simulates the BCH encoder, LDPC encoder, interleaver,
% modulator, as well as their counterparts in the receiver, according to
% the DVB-S.2 standard. The example collects the error rate at the
% demodulator, LDPC decoder, and BCH decoder outputs, determines the
% distribution of the number of iterations performed by the LDPC decoder,
% and shows the received symbol constellation. For more information regarding
% system structure, simplifications, and assumptions, see the
% <commdvbs2.html DVB-S.2 Link, Including LDPC Coding example for
% Simulink(R)>.

%% Initialization
% The <matlab:edit('configureDVBS2Demo.m') configureDVBS2Demo.m> script
% initializes some simulation parameters and generates a structure, dvb.
% The fields of this structure are the parameters of the DVB-S.2 system at
% hand. It also creates the System objects making up the DVB-S.2 system.

rates=[1/4, 1/3, 2/5, 1/2, 3/5, 2/3, 3/4, 4/5, 5/6, 8/9, 9/10 ];    % Constellation and LDPC code rate
rates_string={'1/4';'1/3';'2/5';'1/2';'3/5';'2/3';'3/4';'4/5';'5/6';'8/9';'9/10'};
newrates=rates-needed_coderate;
newrates(newrates>0)=-inf; %to choose the closest rate just below needed rate
[mn,i]=max(newrates);
subsystemType=char(strcat(subsystemType_code,{' '},rates_string(i)));
subsystemType
EsNodB=snr;%        = 1;              % Energy per symbol to noise PSD ratio in dB
numFrames     = numF;%20;             % Number of frames to simulate



% Initialize
configureDVBS2Demo_modified

dvb.rate=ncr;
% Display system parameters
%dvb.NumPacketsPerBBFrame=dvb.NumPacketsPerBBFrame*2;
% dvb.BitPeriod=dvb.BitPeriod/100;
% dvb.NumPacketsPerBBFrame=dvb.NumPacketsPerBBFrame*10;
% dvb.NumBitsPerPacket=dvb.NumBitsPerPacket*10;
dvb

%%
% The following is a list of object handles this example uses:
%
% *Simulation objects:*
%
%  hBCHEnc   - BCH encoder
%  hBCHDec   - BCH decoder
%  hLDPCEnc  - LDPC encoder
%  hLDPCDec  - LDPC decoder
%  hIntrlv   - Block interleaver
%  hDeintrlv - Block deinterleaver
%  hPSKMod   - PSK modulator
%  hPSKDemod - PSK demodulator
%  hChan     - AWGN channel
%
% *Performance measurement objects:*
%
%  hPER      - Packet error rate calculator
%  hBERLDPC  - LDPC decoder output error rate calculator
%  hBERMod   - Demodulator output error rate calculator
%  hRxCont   - Scatter plot of channel output
%  hVar      - Variance of the noise on a frame
%  hMean     - Average of the noise variance

%% LDPC Encoder and Decoder
% Create LDPC encoder and decoder System objects and set the parity check
% matrix according to Section 5.3.1 of the DVB-S.2 standard [ <#12 1> ]. You set
% the IterationTerminationCondition property to 'Parity check satisfied' to
% stop the decoder iterations when all the parity checks are satisfied,
% which reduces the decoding time. Set the MaximumIterationCount property to
% 50, to limit the number of simulation iterations. Set the
% NumIterationsOutputPort to true to output the number of iterations
% performed for each codeword.

hLDPCEnc = comm.LDPCEncoder(dvb.LDPCParityCheckMatrix);

hLDPCDec = comm.LDPCDecoder(dvb.LDPCParityCheckMatrix, ...
    'IterationTerminationCondition', 'Parity check satisfied', ...
    'MaximumIterationCount',         dvb.LDPCNumIterations, ...
    'NumIterationsOutputPort',       true);

%% Stream Processing Loop
% This section of the code calls the processing loop for a DVB-S.2 system.
% The main loop processes the data frame-by-frame, where the system
% parameter dvb.NumPacketsPerBBFrame determines the number of data packets
% per BB frame. The first part of the for-loop simulates the system. The
% simulator encodes each frame using BCH and LDPC encoders as inner and
% outer codes, respectively. The encoded bits pass through an interleaver.
% The modulator maps the interleaved bits to symbols from the predefined
% constellation. The modulated symbols pass through an AWGN channel. The
% demodulator employs an approximate log-likelihood algorithm to obtain soft
% bit estimates. The LDPC decoder decodes the deinterleaved soft bit values and
% generates hard decisions. The BCH decoder works on these hard decisions to
% create the final estimate of the received frame.
% 
% The second part of the for-loop collects performance measurements such as the
% bit error rate and a scatter plot. It also estimates the received SNR value.


numIterVec = zeros(numFrames, 1);
falseVec   = false(dvb.NumPacketsPerBBFrame, 1);



b4Enc_bitSET=logical(randi([0 1], numFrames,dvb.BCHCodewordLength));%zeros(numFrames,dvb.BCHCodewordLength);

Enc_bitSETcell{size(needed_coderates,2)}=[];
dvb_SET=repmat(dvb,size(needed_coderates,2),1);
%h=waitbar(0,'simulating frame ') ;
%textprogressbar('simulating frames: ');
 for i=1:size(needed_coderates,2)
     needed_coderate=needed_coderates(i);   
     newrates=rates-needed_coderate;
    newrates(newrates>0)=-inf; %to choose the closest rate just below needed rate
    [mn,rate_ind]=max(newrates);
    subsystemType=char(strcat(subsystemType_code,{' '},rates_string(rate_ind)));
    subsystemType
        % Initialize
    configureDVBS2Demo_modified
    
    hLDPCEnc = comm.LDPCEncoder(dvb.LDPCParityCheckMatrix);

    hLDPCDec = comm.LDPCDecoder(dvb.LDPCParityCheckMatrix, ...
    'IterationTerminationCondition', 'Parity check satisfied', ...
    'MaximumIterationCount',         dvb.LDPCNumIterations, ...
    'NumIterationsOutputPort',       true);
    dvb.rate=ncr;
    
    dvb
    
    dvb_SET(i)=dvb;
    Enc_bitSET=zeros(numFrames,dvb.LDPCCodewordLength);
    bbFrameTx  = false(hBCHEnc.CodewordLength,1);
for frameCnt=1:numFrames
    %textprogressbar((frameCnt/numFrames)*100);
    %waitbar(frameCnt/numFrames,h,sprintf('rate=%3.2f, snr=%3.2f\nframe %d of %d',needed_coderate,snr,frameCnt,numFrames)) ;
   
    
    % Transmitter, channel, and receiver
    bbFrameTx(1:dvb.BCHCodewordLength) = b4Enc_bitSET(frameCnt,1:dvb.BCHCodewordLength)';
    
%     b4Enc_bitSET(frameCnt,:)=bbFrameTx(1:dvb.BCHCodewordLength);
  
    
    % bchEncOut            = step(hBCHEnc,   bbFrameTx);
    
    ldpcEncOut           = step(hLDPCEnc,  bbFrameTx);
%     ldpcEncOut=[ldpcEncOut; 0; 0] 
    intrlvrOut           = step(hIntrlv,   ldpcEncOut);
    
    Enc_bitSET(frameCnt,:)=intrlvrOut;
    
    modOut               = step(hMod,      intrlvrOut);
    
    chanOut              = step(hChan,     modOut);
    
    demodOut             = step(hDemod,    chanOut);
    
    deintrlvrOut         = step(hDeintrlv, demodOut);
    
    [ldpcDecOut, numIter] = step(hLDPCDec,  deintrlvrOut);
    
    % bchDecOut            = step(hBCHDec,   ldpcDecOut);
    
    bbFrameRx            = ldpcDecOut;%(1:dvb.NumInfoBitsPerCodeword,1);
    
    
    % Error statistics
    comparedBits = xor(bbFrameRx, bbFrameTx(1:dvb.BCHCodewordLength));
%     packetErr    = any(reshape(comparedBits, dvb.NumBitsPerPacket, ...
%                        dvb.NumPacketsPerBBFrame));
%     PER          = step(hPER,      falseVec,   packetErr');
    
    berMod       = step(hBERMod,   demodOut<0, intrlvrOut);

    berLDPC      = step(hBERLDPC,  ldpcDecOut, bbFrameTx(1:dvb.BCHCodewordLength));
    
    % LDPC decoder iterations
    numIterVec(frameCnt) = numIter;

    Zn=chanOut-modOut;
    
    % Noise variance estimate
    noiseVar   = step(hMean, step(hVar, Zn));
    
    calculated_snr=((modOut)'*(modOut))/((chanOut-modOut)'*(chanOut-modOut));
    MI=calcMI(dvb.Xij,Zn,noiseVar,dvb.BitsPerSymbol);
   GMI=calcGMI(chanOut,modOut,dvb.SymbolMapping,dvb.Constellation,noiseVar,dvb.BitsPerSymbol);
   
   
   % Scatter plot
    %step(hRxConst, chanOut);
end
%textprogressbar('done');
%delete(h);
dlmwrite('LLR_space.txt',deintrlvrOut','delimiter',' ','precision','%.2f');

%%
% The step method of the error rate measurement objects, hPER, hBERMod, and
% hBERLDPC, outputs a 3-by-1 vector containing updates of the measured error
% rate value, the number of errors, and the total number of transmissions
% (packets or bits). Display the BER at the demodulator output, the BER at
% the LDPC decoder output, and the packet error rate of the end-to-end
% system together with the measured SNR at the receiver input. While the
% demodulator output presents an error rate of more than 10%, the LDPC
% decoder is able to correct all of the errors and provide error free
% packets.

fprintf('Measured SNR : %1.2f dB\n', 10*log10(1/noiseVar))
fprintf('Modulator BER: %1.2e\n', berMod(1))
fprintf('LDPC BER     : %1.2e\n', berLDPC(1))
% fprintf('PER          : %1.2e\n', PER(1))

modber=berMod(1);
ldpcber=berLDPC(1);


Enc_bitSETcell{i}=Enc_bitSET;
  end
%%
% The figure shows the distribution of the number of iterations performed by
% the LDPC decoder. The decoder was able to decode all the frames without an
% error before reaching the maximum iteration count of 50.

% 
% distFig = figure; hist(numIterVec, 1:hLDPCDec.MaximumIterationCount-1);
% xlabel('Number of iterations'); ylabel('# occurrences'); grid on;
% title('Distribution of number of LDPC decoder iterations')

%%
% We ran the stream processing loop for 32.4e6 bits for several SNR values.
% Since this simulation takes a long time, in this example we only provide
% the result of the simulation stored in a MAT-file.

% 
% load berResultsDVBS2Demo.mat cBER snrdb
% berFig = figure; semilogy(snrdb, cBER(1,:));
% xlabel('SNR (dB)'); ylabel('BER'); grid on

%% Summary
% This example utilized several System objects to simulate part of the
% DVB-S.2 communication system over an AWGN channel. It showed how to model
% several parts of the DVB-S.2 system such as the LDPC coding. System
% performance was measured using the PER and BER values obtained with error
% rate measurement System objects.

%% Further Exploration
% You can modify parts of this example to experiment with different subsystem
% types using various values for Es/No and maximum number of LDPC decoder
% iterations. This example supports the following subsystem types:
%
%       'QPSK 1/4', 'QPSK 1/3', 'QPSK 2/5', 'QPSK 1/2', 
%       'QPSK 3/5', 'QPSK 2/3', 'QPSK 3/4', 'QPSK 4/5', 
%       'QPSK 5/6', 'QPSK 8/9', 'QPSK 9/10'
%
%       '8PSK 3/5', '8PSK 4/5', '8PSK 2/3', '8PSK 3/4', 
%       '8PSK 5/6', '8PSK 8/9', '8PSK 9/10'

%% Appendix
% This example uses the following scripts and helper function:
%
% * <matlab:edit([matlabroot,'\toolbox\comm\commdemos\configureDVBS2Demo.m']) configureDVBS2Demo.m>
% * <matlab:edit([matlabroot,'\toolbox\comm\commdemos\getParamsDVBS2Demo.m']) getParamsDVBS2Demo.m>
% * <matlab:edit([matlabroot,'\toolbox\comm\commdemos\createSimObjDVBS2Demo.m']) createSimObjDVBS2Demo.m>

%% Selected Bibliography
% # ETSI Standard EN 302 307 V1.1.1: _Digital Video Broadcasting (DVB);
% Second generation framing structure, channel coding and modulation systems
% for Broadcasting, Interactive Services, News Gathering and other broadband
% satellite applications (DVB-S2)_, European Telecommunications Standards
% Institute, Valbonne, France, 2005-03.
% # R. G. Gallager, _Low-Density Parity-Check Codes_, IEEE Transactions on 
% Information Theory, Vol. 8, No. 1, January 1962, pp. 21-28. 
% # W. E. Ryan, _An introduction to LDPC codes_, in Coding and Signal 
% Processing for Magnetic Recording Systems (Bane Vasic, ed.), CRC Press, 
% 2004. 

% displayEndOfDemoMessage(mfilename)
