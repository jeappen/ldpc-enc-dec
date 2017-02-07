function subsystemType=closest_rate(needed_coderate,subsystemType)
rates=[1/4, 1/3, 2/5, 1/2, 3/5, 2/3, 3/4, 4/5, 5/6, 8/9, 9/10 ];    % Constellation and LDPC code rate
rates_string={'1/4';'1/3';'2/5';'1/2';'3/5';'2/3';'3/4';'4/5';'5/6';'8/9';'9/10'};
newrates=rates-needed_coderate;
newrates(newrates>0)=-inf; %to choose the closest rate just below needed rate
[mn,i]=max(newrates);
subsystemType=char(strcat(subsystemType,{' '},rates_string(i)));