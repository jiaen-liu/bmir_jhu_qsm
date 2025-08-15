function A=gen_spher_harm_poly(x,y,z,ord)
    x=x(:);
    y=y(:);
    z=z(:);
    [phi,theta,r]=cart2sph(x,y,z);
    n=numel(x);
    npoly=(ord+1)^2;
    A=zeros(n,npoly);
    for i=0:ord
        A(:,(i+1)^2-2*i:(i+1)^2)=spher_harm(i,theta,phi,r);
    end
end