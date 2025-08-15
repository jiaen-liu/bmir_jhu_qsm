function [phase_local, background, mask_eval] = VSHARP_k(GREPhaseSE, BrainMask, radiusArray, SMV_thres, Params, handles)
% [phase_local, background, mask_eval] = VSHARP_k(GREPhaseSE, BrainMask, radiusArray, SMV_thres, Params, handles)
% Author: Xu Li
% Affiliation: Radiology @ JHU
% Email address: xuli@mri.jhu.edu
%
% Ref: Schweser et al. 2011, NIMG, Wu, et al., 2011, MRM, Bilgic, et. al NMRB 2017
% 
% NOTE: k-space based VSHARP implementation, 2017-04, modified from Birkin Bilgic's SSQSM code
% radiusArray is max_radius:step_size_radius:min_radius, does not need to match resolution in the phase data
% Do k-space based V-SHARP for each echo, does not average
% 1. generate k-space based SMV kernals and masks for different radius
% 2. calculate SMV
% 3. do inverse with kernel with maximum radius
% updated 2019-05-21: added in support for odd dimention
% Updated 2019-09-07: Added LapPhaseCorrection, X.L.
% Updated by Xu Li, 2020-10-10
% Updated 2021-06-27 X.L., cluster version

warning off all

if radiusArray(1)<radiusArray(end)
    radiusArray = sort(radiusArray, 'descend');     % sort radiusArray in descending order
end

% Start the clock
textWaitbar = ['Performing V-SHARP on ' num2str(length(Params.echoNums)) ' echoes'];
if ~isfield(Params, 'cluster')
    multiWaitbar(textWaitbar, 0, 'CanCancel', 'On' );
else
    disp(textWaitbar);
end

% Cut only what we want
GREPhaseData = GREPhaseSE(:,:,:,Params.echoNums);
GRETEs = Params.TEs(Params.echoNums);
phase_local = zeros(size(GREPhaseData), class(GREPhaseData));       % final output

% Create k-space kernel with different radius 
N = size(BrainMask);
if N ~= Params.sizeVol
    disp('check Params.sizeVol')
end
% under N coordinate
[Y,X,Z] = meshgrid(-floor(N(2)/2):ceil(N(2)/2-1),-floor(N(1)/2):ceil(N(1)/2-1),-floor(N(3)/2):ceil(N(3)/2-1));

X = X * Params.voxSize(1);
Y = Y * Params.voxSize(2);
Z = Z * Params.voxSize(3);

num_kernel = length(radiusArray);   % number of kernels
unrely_tol = 1e-3;                  % tol for unreliable boundary voxels
SMV_kernel = zeros([N, num_kernel]);
mask_Sharp = zeros([N, num_kernel]);
mask_prev = zeros(N);
SMV_inv_kernel = zeros(N);          % tsvd

for k = 1:num_kernel

    SMV = gen_SMVkernel_voxel_scaled( X, Y, Z, radiusArray(k));     % kernel in k-space
    mask_rely = gen_SMVMask_new( SMV, BrainMask, unrely_tol);       % reliable mask
    
    if sum(mask_rely(:)) == 0
        continue
    end
    
    SMV_kernel(:,:,:,k) = SMV;
    mask_Sharp(:,:,:,k) = (mask_rely-mask_prev);
    mask_prev = mask_rely;
        
    if k == 1                               % with max_radius
        SMV_inv_kernel( abs(SMV) > SMV_thres ) = 1 ./ SMV( abs(SMV) > SMV_thres );
    end
    
    if ~isfield(Params, 'cluster')
        hasCanceled = multiWaitbar(textWaitbar, 0.5*(k/num_kernel));
        HandleStopReconstruction;
    else
        disp([num2str(100*0.5*(k/num_kernel)), '% Done.']);
    end    
end
    
mask_eval = sum(mask_Sharp, 4) > 0;         %   final mask for evalualtion 


%% Do the loop for all echoes
procNechos = size(GREPhaseData,4);
for selectedEcho = 1:procNechos

    phase_local(:,:,:,selectedEcho) = fftn(GREPhaseData(:,:,:,selectedEcho));
    phase_Sharp = zeros(N);
    
    % convolve with V-SHARP kernels
    for k = 1:num_kernel
        phase_Sharp = phase_Sharp +  mask_Sharp(:,:,:,k).* ifftn(SMV_kernel(:,:,:,k) .*phase_local(:,:,:,selectedEcho));
    end      
    
    % deconvolution
    phase_local(:,:,:,selectedEcho) = mask_eval.*ifftn(SMV_inv_kernel.*fftn(phase_Sharp));
    
    if ~isfield(Params, 'cluster')
        hasCanceled = multiWaitbar(textWaitbar, 0.5+0.5*(selectedEcho/procNechos));
        HandleStopReconstruction;
    else
        disp([num2str(100*(0.5+0.5*(selectedEcho/procNechos))), '% Done.']);
    end
    
    % LapPhaseCorrection, 2019-09-07, xl    
    % Params.LapPhaseCorrection = 0;  % for testing     
    if isfield(Params, 'LapPhaseCorrection')
        if Params.LapPhaseCorrection == 1
            temp = angle(exp(1i*phase_local(:,:,:,selectedEcho).*(2*pi*GRETEs(selectedEcho))));
            temp = phase_unwrap_laplacian(temp, Params, 0, 2);     % no Ref
            phase_local(:,:,:,selectedEcho) = temp./(2*pi*GRETEs(selectedEcho)).*mask_eval;
        end
    end    
end

% Calculate background
background = (GREPhaseData - phase_local).*repmat(mask_eval, [1 1 1 size(GREPhaseData, 4)]);

% Average everything
phase_local = mean(phase_local,4);
background = mean(background,4);

%% subfunctions
function SMV = gen_SMVkernel_voxel_scaled( X, Y, Z, smv_rad)
  
    smv = (X.^2 + Y.^2 + Z.^2) <= smv_rad^2;
    smv = smv / sum(smv(:));                    % normalized 

    smv_kernel = zeros(size(X));
    smv_kernel(1+floor(end/2),1+floor(end/2),1+floor(end/2)) = 1;    
    smv_kernel = smv_kernel - smv;              % delta - smv

    SMV = fftn(fftshift(smv_kernel));           % kernel in k-space 

end

function mask_rely = gen_SMVMask_new( SMV, chi_mask, unrely_tol)
  
    mask_unrely = ifftn(SMV .* fftn(chi_mask));             
    mask_unrely = abs(mask_unrely) > unrely_tol;            

    mask_rely = chi_mask .* (chi_mask - mask_unrely);       

end


end
