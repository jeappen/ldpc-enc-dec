## Instructions:
- Use encode_maher
```matlab
  [dvb,Enc_bitSET,b4Enc_bitSET,frame1234] = encode_maher(needed_coderate, num_frames, subsystemType_code, save_encbits, use_bch , use_interleaver)
```
- save the dvb structure for decoding at a later time
- Use decode_maher
```matlab
  [decoded_data, preFEC] = decode_maher(dvb,soft_data,EsNo)
```
- Compare this decoded data with the b4Enc_bitSET (or the first k bits of the frame) to check the BER.

## encode_maher

Picks nearest standard code to puncture.

Input:  


needed_coderate, number of frames,

		save_encbits = save encbits to .mat file
   
		use_bch = to concatenate bch or not
    
        use_interleaver = to use interleaving
        
Output: 

Hmatrix_rate<needed_coderate>.mat

		Encodedbits_rate<needed_coderate>.mat (if save_encbits == true)
    
        frame1234 : after running split_bitstream.m to format the data.
        
## decode_maher

Input: 

dvb = structure with all the coding parameters including H matrix,
              use_bch and use_interleaver
              
        soft_data = complex valued vector of an integer number of frames
        
        EsNo= OSNR*2*Bref/Rs

Output: 

        decoded_data = logical array
        
        preFEC decoded data (optional)
