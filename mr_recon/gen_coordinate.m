% 2022.09.22 Included philids version when snormal is a 9x1 vector, it is actually the needed matrix
function c=gen_coordinate(snormal, rot)
%     
% returns a matrix to calculate scanner rl,ap,fh coordinates from image indices
% so that [rl,ap,fh]= matrix # [im_x,im_y,imz]
% note the offset (position) is not in this calculation and should be added to the resulting vector.
%   
% It is assumed the image recon inverts the RO, to transform the Siemens acquisition [pe,ro,sl] to [-ro,pe,sl] in the image data
%
    if size(snormal,1)==9
        c=reshape(snormal(:,1),[3,3]);
        return;
    end
    snormal=snormal(:,1);
    [~,imax_normal]=max(snormal(:,1),[],1);

% p defines direction of PE without in plane rotation
    switch imax_normal
    	case 1
        	p= [-snormal(2),snormal(1),0]/sqrt(snormal(1)^2+ snormal(2)^2) ; % sag (nx), rot=0: AP PE, FH RO
  		case 2
         	p= [snormal(2),-snormal(1),0]/sqrt(snormal(1)^2+ snormal(2)^2) ; % cor (ny), rot=0: RL PE, HF RO
  		case 3 
        	p= [0,snormal(3),-snormal(2)]/sqrt(snormal(2)^2+ snormal(3)^2) ; % tra (nz), rot=0: AP PE, LR RO
    end   	

% r is perpendicular to normal & p, note p,r,n from RH system, so r= n X p (as in y= z X x)
	r= [snormal(2)*p(3)- snormal(3)*p(2),snormal(3)*p(1)- snormal(1)*p(3),snormal(1)*p(2)- snormal(2)*p(1)];
    
% do inplane rotation. this seems to be a left hand turn around normal
    x_axis=rot_vector_3d(r,snormal,-rot);
    y_axis=rot_vector_3d(p,snormal,-rot);    
    z_axis= snormal;

	x_axis= -x_axis; % x (readout) gets inverted in Jiaen's recon convention
    
    c=[x_axis,y_axis,z_axis];
end
