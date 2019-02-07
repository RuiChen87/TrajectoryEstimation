
function [ft,range]=regionFeatures(img, pr, cur_scale, max_scale, modelSize, cos_window, featureRatio)
%regionFeatures: ͼ��ֲ�������ȡ���� ��ȡ������������RGB/gray��HOG����
%   ���룺
%   - img ��ǰͼ��
%   - pr ��ǰλ��
%   - cur_scale ��ǰͼ�����
%   - max_scale ������
%   - modelSize ģ�ͳߴ�
%   - cos_window cosȨ������
%   - featureRatio �����������

%   �����
%   - ft �ֲ�����
%   - sz ��������ߴ�

% ����׼��
if(cur_scale>max_scale) %Լ����Գߴ�
    cur_scale=max_scale;
end

xr=floor(modelSize(1)*cur_scale); %��������ߴ�
yr=floor(modelSize(2)*cur_scale);

xr=max(xr,2);
yr=max(yr,2);

range=zeros(1,4);   %���ز�����Χ��2��Ŀ��ߴ�
range(1)=floor(pr(1)-(xr-1)/2);
range(2)=range(1)+xr-1;
range(3)=floor(pr(2)-(yr-1)/2);
range(4)=range(3)+yr-1;

% ��ɢ�����õ��ߴ��һ������ͼ��
xs=floor(range(1):range(2));
ys=floor(range(3):range(4));

% ���Ʋ�����Χ
[n,m,~]=size(img);
ys(ys<1)=1;
ys(ys>n)=n;
xs(xs<1)=1;
xs(xs>m)=m;

% ��ȡ�ֲ�ͼ������
c=size(img,3);
% sub_img=imresize(img(ys,xs,:),[modelSize(2),modelSize(1)],'bilinear');
sub_img=mexResize(img(ys,xs,:),[modelSize(2),modelSize(1)], 'auto');

% ����cos���ֲ�������
cos_img=single(sub_img).*cos_window(:,:,ones(c,1));

% ��������
ft=featureExtract(cos_img,modelSize,featureRatio);

end

function ft=featureExtract(img,modelSize,featureRatio)
%featureExtract: ������ȡ���� ��ȡ������������RGB/gray��HOG����
%   ���룺
%   - img ͼ��
%   - modelSize ģ�ͳߴ�
%   - featureRatio �����������

%   �����
%   - ft ��ǰͼ�������ͼ

c=size(img,3);
new_sz=fix([modelSize(2)/featureRatio,modelSize(1)/featureRatio]);
ft=single(zeros(new_sz(1),new_sz(2),31+c));

% ��ȡHog����
ft(:,:,1:32)=fhog(single(img),featureRatio);
% sp_img=imresize(img,fix([modelSize(2)/featureRatio,modelSize(1)/featureRatio]),'bilinear');
sp_img=mexResize(img,new_sz, 'auto');

% ��RGB��Ϊ����
if(size(img,3)==3)
    ft(:,:,32:34)=single(sp_img);
else
    ft(:,:,32)=single(sp_img);
end
end