function [tracker,pos]=paramsInitialize(basicPara)
% fDSST ������ʼ������
% ���룺
%   @basicPara �������� 
% �����
%   @tracker ��ʼ��������
%   @pos ��ʼ��Ŀ������

padding = basicPara.padding;   %��ʼ��
output_sigma_factor = basicPara.output_sigma_factor;   %��ʼ��
lambda = basicPara.lambda; %estimate
interp_factor = basicPara.interp_factor;   %train
refinement_iterations = basicPara.refinement_iterations;   %estimate
translation_model_max_area = basicPara.translation_model_max_area; %��ʼ��
nScales = basicPara.number_of_scales;  %��ʼ��, estimate, train
nScalesInterp = basicPara.number_of_interp_scales; %��ʼ����estimate
scale_step = basicPara.scale_step; %��ʼ��
scale_sigma_factor = basicPara.scale_sigma_factor;%��ʼ��
scale_model_factor = basicPara.scale_model_factor;%��ʼ��
scale_model_max_area = basicPara.scale_model_max_area;%��ʼ��
interpolate_response = basicPara.interpolate_response;%estimate
num_compressed_dim = basicPara.num_compressed_dim;%��ʼ����train

tracker.lambda=lambda;
tracker.interp_factor=interp_factor;
tracker.refinement_iterations=refinement_iterations;
tracker.nScales=nScales;
tracker.nScalesInterp=nScalesInterp;
tracker.interpolate_response=interpolate_response;
tracker.num_compressed_dim=num_compressed_dim;


s_frames = basicPara.s_frames;%�洢ͼ��
pos = floor(basicPara.init_pos);%Ŀ��λ�ã���������
target_sz = floor(basicPara.wsize * basicPara.resize_factor); %��ǰĿ��ߴ磬Ϊʱ����

tracker.s_frames=s_frames;
tracker.target_sz=target_sz;

num_frames = numel(s_frames);%ͼ�����
tracker.num_frames=num_frames;

init_target_sz = target_sz;%��ʼĿ��ߴ磬Ϊ����

if prod(init_target_sz) > translation_model_max_area
    currentScaleFactor = sqrt(prod(init_target_sz) / translation_model_max_area);
else
    currentScaleFactor = 1.0;
end
tracker.currentScaleFactor=currentScaleFactor;

% target size at the initial scale
base_target_sz = target_sz / currentScaleFactor;%����Ŀ��ߴ磬Ϊ����
tracker.base_target_sz=base_target_sz;

%window size, taking padding into account
sz = floor( base_target_sz * (1 + padding ));   %�������ʼ�ߴ磬����
tracker.sz=sz;

featureRatio = 4;   %�����ߴ磬����
tracker.featureRatio=featureRatio;

output_sigma = sqrt(prod(floor(base_target_sz/featureRatio))) * output_sigma_factor;%����
use_sz = floor(sz/featureRatio);    %ѹ����������ߴ磬�����ڳ�ʼ��
rg = circshift(-floor((use_sz(1)-1)/2):ceil((use_sz(1)-1)/2), [0 -floor((use_sz(1)-1)/2)]);
cg = circshift(-floor((use_sz(2)-1)/2):ceil((use_sz(2)-1)/2), [0 -floor((use_sz(2)-1)/2)]);

[rs, cs] = ndgrid( rg,cg);
y = exp(-0.5 * (((rs.^2 + cs.^2) / output_sigma^2)));
yf = single(fft2(y));%�öδ�������ڼ���Ŀ�����������˹�ֲ���

tracker.y=y;
tracker.yf=yf;

interp_sz = size(y) * featureRatio; %estimate��
tracker.interp_sz=interp_sz;

cos_window = single(hann(floor(sz(1)/featureRatio))*hann(floor(sz(2)/featureRatio))' );%�öδ�������ڼ���cos����
tracker.cos_window=cos_window;

if nScales > 0
    scale_sigma = nScalesInterp * scale_sigma_factor;
    
    scale_exp = (-floor((nScales-1)/2):ceil((nScales-1)/2)) * nScalesInterp/nScales;
    scale_exp_shift = circshift(scale_exp, [0 -floor((nScales-1)/2)]);
    
    interp_scale_exp = -floor((nScalesInterp-1)/2):ceil((nScalesInterp-1)/2);
    interp_scale_exp_shift = circshift(interp_scale_exp, [0 -floor((nScalesInterp-1)/2)]);
    
    scaleSizeFactors = scale_step .^ scale_exp;%���� estimate,train
    interpScaleFactors = scale_step .^ interp_scale_exp_shift;%����train
    
    tracker.scaleSizeFactors=scaleSizeFactors;
    tracker.interpScaleFactors=interpScaleFactors;
    
    ys = exp(-0.5 * (scale_exp_shift.^2) /scale_sigma^2);
    ysf = single(fft(ys));%�ߴ�仯train�õ�Ŀ���˹�ֲ�
    scale_window = single(hann(size(ysf,2)))';%�ߴ�仯 estimate,train �õ�cos����
    
    tracker.ysf=ysf;
    tracker.scale_window=scale_window;
    
    %make sure the scale model is not to large, to save computation time
    if scale_model_factor^2 * prod(init_target_sz) > scale_model_max_area
        scale_model_factor = sqrt(scale_model_max_area/prod(init_target_sz));
    end
    
    %set the scale model size
    scale_model_sz = floor(init_target_sz * scale_model_factor);%�ߴ�仯 estimate,train �õ�ģ�ͳߴ�
    tracker.scale_model_sz=scale_model_sz;
    
    im = imread(s_frames{1});
    
    %force reasonable scale changes �ߴ������Χestimate��
    min_scale_factor = scale_step ^ ceil(log(max(5 ./ sz)) / log(scale_step));%estimate
    max_scale_factor = scale_step ^ floor(log(min([size(im,1) size(im,2)] ./ base_target_sz)) / log(scale_step));%estimate
    
    tracker.min_scale_factor=min_scale_factor;
    tracker.max_scale_factor=max_scale_factor;
    
    max_scale_dim = strcmp(basicPara.s_num_compressed_dim,'MAX');  %���ߴ�ά�� train ��
    if max_scale_dim
        s_num_compressed_dim = length(scaleSizeFactors);    % train ��
    else
        s_num_compressed_dim = basicPara.s_num_compressed_dim;
    end
    tracker.max_scale_dim=max_scale_dim;
    tracker.s_num_compressed_dim=s_num_compressed_dim;
end

% initialize the projection matrix
projection_matrix = []; %estimate,train ʹ��
tracker.projection_matrix=projection_matrix;

rect_position = zeros(num_frames, 4);%Ŀ���Χ��estimate������
tracker.rect_position=rect_position;

end