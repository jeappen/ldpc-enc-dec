function dvb = encode_maher(needed_coderate,s,s1)
%{
Picks nearest standard code to puncture.

Input:  needed_coderate, number of frames,
		save_encbits = save encbits to .mat file
		use_bch = to concatenate bch or not

Output: Hmatrix_rate<needed_coderate>.mat
		Encodedbits_rate<needed_coderate>.mat (if save_encbits == true)
%}

end