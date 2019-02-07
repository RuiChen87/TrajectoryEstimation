function ft_scales=scaleFeaturs(img, pr, modelSize, scales, max_scale, cos_window, featureRatio)
%scaleFeaturs: ͼ���߶�������ȡ���� ��ȡ������������RGB/gray��HOG����
%   ���룺
%   - img ��ǰͼ��
%   - pr ����λ�� (x,y)
%   - modelSize ģ�ͳߴ�
%   - scales ������Թ�ģ
%   - max_scale ��������ģ
%   - cos_window cosȨ������
%   - featureRatio �����������

%   �����
%   - ft_scales ���ֲ�����

n_sc=length(scales);    %������ģ��
n_feature=fix(modelSize(1)/featureRatio)*fix(modelSize(2)/featureRatio)*31; %ÿһ������ά��
% ft_scales_0=zeros(n_feature,n_sc);                                %����ʼ����
% ft_scales=zeros(n_sc,n_sc);                                       %ѹ������
ft_scales=single(zeros(n_feature,n_sc));                            %ѹ������
% ft_size=zeros(n_sc,2);

for i=1:n_sc
    % ����������Χ
    cur_scale=min(scales(i),max_scale);
    
    % �ó߶��µ�����
    cur_ft=regionFeatures(img, pr, cur_scale, max_scale, modelSize, cos_window, featureRatio);
    ft_scales(:,i)=reshape(cur_ft(:,:,1:31), n_feature, 1);
end

% ���ɷַ���(����)
% ft_scales=
end