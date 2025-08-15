function ord_mat=polyns(m,n)
% number of monomials: (m+n-1)!/((m-1)!*n!)
% m dimention; n order
    if m==1
        ord_mat=n;
    else
        ord_mat=[n;zeros(m-1,1)];
        for k=1:n
            ord_mat_tmp=polyns(m-1,k);
            size_tmp=size(ord_mat_tmp);
            if (numel(size_tmp)==2 && size_tmp(2)==1)
                ord_mat_tmp=[n-k;ord_mat_tmp];
            else
                ord_mat_tmp=[n-k+zeros(1,size_tmp(2));ord_mat_tmp];
            end
            ord_mat=[ord_mat,ord_mat_tmp];
        end
    end
end