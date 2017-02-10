%Each frame is a separate LDPC codeword
bits_per_symbol=4; %Enter number of bits per symbol here

%this will split the encoded data into a 3D array of bits_per_symbol column
%vectors and number of frames (also called codeword)

% load('enc_bits_fixed.mat');
numFrames=size(Enc_bitSET,1);
Codeword_length=size(Enc_bitSET,2);
num_symbols_per_frame=Codeword_length/bits_per_symbol;
Bitstreams=zeros(num_symbols_per_frame,bits_per_symbol,numFrames);
% b4Enc_bitSET is the message data being sent per frame
% Enc_bitSET is the LDPC encoded data. eg: currently 10 LDPC codewords with length 64800

for i=1:bits_per_symbol
    a=Enc_bitSET(:,i:bits_per_symbol:end);
    b=reshape(a',num_symbols_per_frame,1,numFrames);
    Bitstreams(:,i,:)=b;
end

%example: for frame 1, here are the individual bit streams
frame1=Bitstreams(:,:,1);
%for frame2
frame2=Bitstreams(:,:,2);
frame3=Bitstreams(:,:,3);
%for frame2
frame4=Bitstreams(:,:,4);
%for close to 2^16 symbols

num_repetitions=1;
frame1234=repmat([frame1;frame2;frame3;frame4],num_repetitions,1);