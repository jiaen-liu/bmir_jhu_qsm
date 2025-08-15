function y=sphere_harm_calc_3d(x,y,z,c)
    n=size(c,1);
    x=x(:);
    y=y(:);
    z=z(:);
    ord=round(n^0.5)-1;
    A=gen_spher_harm_poly(x,y,z,ord);
    y=A*c;
end