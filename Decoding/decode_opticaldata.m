Bref=12.5e6;12.5e6; %GHz
Rs=25e6; %GBd
bits_per_symbol=4;

num_frames=10;


          indexset=[1:16];

        maxNumLDPCIterations=50;

% needed_coderate=5/6;0.9;5/6; %not supported for non-standard rates since encoding H matrix should be stored.

subsystemType_modscheme='16QM';
subsystemType='16QM';
% subsystemType=closest_rate(needed_coderate,subsystemType);

OSNRsdB=[5:20];
OSNRs=10.^(OSNRsdB./10);
EsNos=OSNRs*2*Bref/Rs;
EsNosdB=10*log10(EsNos);
NoiseVars=1./EsNos;%10.^(-EsNosdB./10);

% load('encodedbits.mat') %need this for the message bits
% load(['soft_data_ldpc_' lower(subsystemType_modscheme) '.mat'])
% % load('preFEC_ber.mat')
% load(['framedata_' lower(subsystemType_modscheme) '.mat']) %the sent bits (after doing error control coding
% load('frame1234_rate0.9_16QAM.mat')
% load('preFEC_Soft_data_9by10_LDPC.mat');
% load('frame1234_rate5by6_16QAM.mat')
% load('preFEC_Soft_data_5by6_LDPC.mat');
% load('preFEC_Soft_data_5by6_LDPC_16QAM_test.mat');
% sent=frame1234'; %for BER calculation


load('ENCBITSET_withinterleaving.mat');
load('frame1234_WithInterleaving.mat');
softdata_files=dir('Softdata_16QAM_Codeindex_*');


ldpc_BERs_allOH=zeros(size(softdata_files,1),size(indexset,2));
preFEC_BERs_allOH=zeros(size(softdata_files,1),size(indexset,2));
numIter_allOH=zeros(size(softdata_files,1),size(indexset,2));

ldpc_BERs=zeros(1,size(indexset,2));
preFEC_BERs=zeros(1,size(indexset,2));
numIter_set=zeros(1,size(indexset,2));

for file_ind=1:size(softdata_files,1)
    
    
            load(softdata_files(file_ind).name);
%             soft_data=
          sent=cell2mat(Enc_bitSETcell(file_ind))';%frame1234SET(file_ind));%Enc_bitSETcell(file_ind))';
          dvb=dvb_SET(file_ind);


        symb_map=[3 1 0 2]; [2 0 1 3];%wrt to clockwise ordering of constellation
        symb_mapQAM=[3 2 0 1 7 6 4 5 15 14 12 13 11 10 8 9];[0:2^bits_per_symbol-1];

         symb_mapQAM2=zeros(size(symb_mapQAM));
         symb_mapQAM2(symb_mapQAM+1)=[0:15];

        BCHCodeword_Length=dvb.BCHCodewordLength;54000; %54000 for 5by6 code
        num_infobits=dvb.BCHCodewordLength;%64800*needed_coderate;
        size_ldpc_codeword=dvb.LDPCCodewordLength;64800;
        symbols_per_frame=size_ldpc_codeword/bits_per_symbol;
        infobits=sent(1:num_infobits)';
        infobits=infobits>0;

        ldpc_BERs=zeros(1,size(indexset,2));
        preFEC_BERs=zeros(1,size(indexset,2));
        numIter_set=zeros(1,size(indexset,2));

        for i=1:size(indexset,2) %
        index=indexset(i);
        setup_decode_objects;
            wrong_bits=0;
            preFEC_wrong_bits=0;
            numIters=zeros(num_frames,1);
            for j=1:num_frames
            % demodOut5=LLRcalc_norm(soft_data(:,index),EsNos(index),bits_per_symbol);   %works for QPSK
                message       = step(hDeintrlv, sent((mod(j-1,4))*size_ldpc_codeword+1:((mod(j-1,4)+1))*size_ldpc_codeword)'); %deinterleave to get sent message+parity check bits

             demodOut5           = step(hDemodQAM,    soft_data((j-1)*symbols_per_frame+1:j*symbols_per_frame,index));
        %     demodOut5=LLRcalc(soft_data((j-1)*symbols_per_frame+1:j*symbols_per_frame,index),EsNos(index),bits_per_symbol,true);

        % preFEC(preFEC>=0)=0;
            % preFEC(preFEC<0)=1;

                preFEC=demodOut5<0; 
                deintrlvrOut5       = step(hDeintrlv, demodOut5(1:size_ldpc_codeword));


                [ldpcDecOut5, numIter] = step(hLDPCDec,  deintrlvrOut5);

        %         ldpcDecOut5_full=ldpcDecOut5_soft<0;
        %         ldpcDecOut5=ldpcDecOut5_full(1:dvb.BCHCodewordLength);

                bchDecOut5            = step(hBCHDec,   ldpcDecOut5);
                bbFrameRx5         = ldpcDecOut5;%bchDecOut5(1:dvb.NumInfoBitsPerCodeword,1);

                infobits=sent((mod(j-1,4))*size_ldpc_codeword+1:(mod(j-1,4)+1)*size_ldpc_codeword)';
                infobits=infobits(1:BCHCodeword_Length)>0;
        %         infobits=infobits;

                wrong_bits=wrong_bits+sum(~(bbFrameRx5==message(1:BCHCodeword_Length))); %check with message data
                preFEC_wrong_bits=preFEC_wrong_bits+sum(~(infobits==preFEC(1:BCHCodeword_Length))); % tried comparing the entire codeword for preFEC BER
                status1=[wrong_bits,numIter]
                numIters(j)=numIter;
            end
            status=[i,wrong_bits,preFEC_wrong_bits]
            numIter_set(i)=mean(numIters);
            ldpc_BERs(i)=wrong_bits/(BCHCodeword_Length*num_frames);
            preFEC_BERs(i)=preFEC_wrong_bits/(BCHCodeword_Length*num_frames);

        end
      ldpc_BERs_allOH(file_ind,:)=ldpc_BERs;
      preFEC_BERs_allOH(file_ind,:)=preFEC_BERs;
      numIter_allOH(file_ind,:)=numIter_set;
end




min_measurable_BER=1/(BCHCodeword_Length*num_frames);

ldpc_BERs
preFEC_BERs

%% Plotting BERs
% 0 BER will be replaced by a dashed line to represent minimum measurable BER
BER_vs_SNR=figure;
plottitle='BERvsSNR';

ldpc_BERs_toplot=ldpc_BERs;
% ldpc_BERs_toplot(ldpc_BERs_toplot==0)=min_measurable_BER;

preFEC_BERs_toplot=preFEC_BERs;
% preFEC_BERs_toplot(preFEC_BERs_toplot==0)=min_measurable_BER;

semilogy(EsNosdB(indexset), preFEC_BERs_toplot,'r.-');
hold on;
semilogy(EsNosdB(indexset), ldpc_BERs_toplot,'bo--');
semilogy(EsNosdB(indexset), repmat(min_measurable_BER,1,size(indexset,2)),'g-');
hold off;



t1=title([subsystemType_modscheme ' BER vs $\frac{Es}{No}$']);
set(t1,'Interpreter','Latex');
xl1=xlabel('$\frac{Es}{No}$ (dB)');
set(xl1,'Interpreter','Latex');
ylabel('BER');
grid on

legend('preFEC','postFEC (LDPC)','min measurable BER')
saveas(BER_vs_SNR,[plottitle '.fig']);
%% Ploting num iteration vs SNR
numIter_vs_SNR=figure;
plottitle='numiterVsSNR';

plot(EsNosdB(indexset), numIter_set,'bo');

t2=title([subsystemType_modscheme ' \# Iterations vs $\frac{Es}{No}$ ']);
set(t2,'Interpreter','Latex');
xl2=xlabel('$\frac{Es}{No}$ (dB)');
set(xl2,'Interpreter','Latex');
xlabel('$\frac{Es}{No}$ (dB)');
ylabel('#Iterations');
ylim([0 max(numIter_set)+1]);
saveas(numIter_vs_SNR,[plottitle '.fig']);