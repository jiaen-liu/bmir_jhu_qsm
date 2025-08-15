function y=rot_vector_3d(v,axis,theta)
    v=v(:);
    axis=axis(:);
    axis=axis/norm(axis);
    va=v.'*axis*axis;
    vb=v-va;
    if vb==0
        y=v;
        return;
    end
    v3=cross(axis,vb);
    % vb will be rotated around axis by theta
    vb1=vb*cos(theta);
    vb2=v3*sin(theta);
    vbrot=vb1+vb2;
    y=vbrot+va;
end