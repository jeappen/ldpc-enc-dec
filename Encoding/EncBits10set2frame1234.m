% load('ENCBITSET.mat');
load('ENCBITSET_withinterleaving.mat')
num_of_rates=size(needed_coderates,2);
frame1234SET{num_of_rates}=[];
for rate_ind=1:num_of_rates
    Enc_bitSET=cell2mat(Enc_bitSETcell(rate_ind));
    split_bitstream;
    frame1234SET{rate_ind}=frame1234;
end