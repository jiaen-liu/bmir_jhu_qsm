function y=spher_harm(l,theta,phi,r)
    n=numel(theta);
    y=zeros(n,2*l+1);
    Pn=legendre(l,sin(theta),'norm');
    phi=phi(:).';
    r=r(:).';
    for i=0:l
        Pn(i+1,:)=(1/(2*pi))^0.5*...
                  (Pn(i+1,:).*exp(1i*i*phi).*r.^l);
    end
    y(:,l+1)=real(Pn(1,:));
    for i=1:l
        y(:,i+l+1)=2^0.5*real(Pn(i+1,:));
        y(:,i)=2^0.5*imag(Pn(end+1-i,:));
    end
end