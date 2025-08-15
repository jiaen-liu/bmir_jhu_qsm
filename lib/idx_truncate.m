function [idx_arr,i1,i2]=idx_truncate(n,nn,sym)
% sym: define where original is
% 1: always symmetric; 0: zero is at floor(n/2)+1
    if nargin<3
        sym=0;
    end
    if sym==0
        izero=floor(n/2)+1;
        izeron=floor(nn/2)+1;
        i1=izero-izeron+1;
        i2=izero+nn-izeron;
    else
        % n and nn have to be the same odd or even
        if mod(n-nn,2)==1
            error('*** The truncated and original array sizes  should be the same odd/evenness! ***');
        end
        i1=(n-nn)/2+1;
        i2=(n+nn)/2;
    end
    idx_arr=[i1:i2];
end