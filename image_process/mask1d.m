function [mask,thrd]=mask1d(mag,frac,rel)
    magi=mag;
    if nargin<2
        frac=0.3;
    end;
    if nargin<3
        rel=0.1;
    end;
    % cut the first and last two points
    mag=mag(2:end-2);
    mag=sort(mag);
    n=length(mag);
    noise=mag(1:floor(n*frac));
    aveNoise=mean(noise);
    % stdNoise=std(noise,0);
    % mask=magi>(aveNoise+nstd*stdNoise);
    thrd=aveNoise+(mag(end)-aveNoise)*rel;
    mask=magi>thrd;
end