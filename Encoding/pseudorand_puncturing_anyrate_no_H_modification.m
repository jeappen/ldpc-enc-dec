% H = dvbs2ldpc(3/5)
% spy(H)
function [H_new,new_coderate]=pseudorand_puncturing_anyrate_no_H_modification(needed_coderate,bits_per_symbol)

if nargin==1
    bits_per_symbol=1;
end
% coderate=3/5;1/2; % choose from the existing code rates
% num_puncture=2e4; %number of parity bits to remove
%gets H matrix from the dvbs2 standard
rates=[1/4, 1/3, 2/5, 1/2, 3/5, 2/3, 3/4, 4/5, 5/6, 8/9, 9/10 ];
newrates=rates-needed_coderate;
newrates(newrates>0)=-inf; %to choose the closest rate just below needed rate
[mn,i]=max(newrates);
coderate=rates(i);
H = dvbs2ldpc(coderate);
n=size(H,2);
m=size(H,1);
k=n-m;
num_puncture=round(n-k/needed_coderate);
num_puncture=num_puncture-mod(num_puncture,bits_per_symbol);
% spy(H)
% spy(H(:,32400:end))
Sparse_eye=H(:,k+1:end); %since making such a large matrix is costly

Ptrans=H(:,1:k);



% P=Ptrans';
% spy(P)

puncture_index=randperm(m);%round(rand(num_puncture,1)*m);
set1=puncture_index(1:num_puncture);
set2=puncture_index(num_puncture+1:end);
set2index=1;
colsum=sum(Ptrans,1);
indexset=[];
k=size(Ptrans,2);
emptyrow=sparse(1,k);
for index=set1
    index_toberemoved=index;
    toberemoved=Ptrans(index_toberemoved,:);
    nextcolsum=colsum-toberemoved;
    while ~isempty(find(nextcolsum==0, 1))
        if(set2index==size(set2,2))
            msg = 'Cannot make required H for this rate without modifying it';
            error(msg)
        end
        index_toberemoved=set2(set2index);
        set2index=set2index+1;
        toberemoved=Ptrans(index_toberemoved,:);
        nextcolsum=colsum-toberemoved;
    end
    colsum=nextcolsum;
    indexset=[indexset index_toberemoved];
    Ptrans(index_toberemoved,:)=emptyrow;
end

Ptrans(indexset,:)=[];

Sparse_eye=Sparse_eye(1:end-num_puncture,1:end-num_puncture);


% 
% %to randomly make zero columns, nonzero
% 
% zerocol=~sum(Ptrans,1);
% num_zerocol=sum(zerocol)
% ind=[randi(size(Ptrans,1),1,sum(zerocol)); find(zerocol)];
% separate=(ind(2,:)-1)*size(Ptrans,1)+ind(1,:);
% Ptrans(separate)=1;




H_new=[Ptrans Sparse_eye];
new_coderate=k/(n-num_puncture);
% spy(H_new);