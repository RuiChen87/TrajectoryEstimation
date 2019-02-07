%   ���ݼ����غ���
function dataset=loadDataset(im_path,gt_path,gt_type)
%   ���룺
%   - ���ݼ�ͼ��·�� im_path
%   - ��ע·�� gt_path
%   - ͼ����ֵ�洢��ʽ gt_type

%   �����
%   - ���ݼ����� dataset ������
%       - ͼ��·�� dataset.imagePath 
%       - ÿһ֡����ֵ dataset.groundTruth
%       - ��ֵ�洢��ʽ dataset.gtType
%       - ͼ����� dataset.imageNumber

%% ��ȡͼƬ
%   ��ȡͼƬ��ʽ
im_type=['/*.jpg';'/*.png';'/*.bmp'];

for i=1:3
    img_path_list = dir([im_path,im_type(i,:)]); %��ȡ���ļ���������jpg��ʽ��ͼ��
    img_num = length(img_path_list);        %��ȡͼ��������
    
    if(img_num)
        break;
    end
end

dataset.imagePath=cell(img_num,1);
for i=1:img_num
    dataset.imagePath{i}=fullfile(im_path,img_path_list(i).name);
end

dataset.imageNumber=img_num;
dataset.gtType=gt_type;

%%  ��ȡGround Truth
dataset.groundTruth=cell(img_num,1);

gt_type=gt_path(length(gt_path)-3:length(gt_path));
if(~strcmp(gt_type,'.txt'))
    flist = dir([gt_path,'/*.txt']); %��ȡ���ļ���������txt
    gt_path=fullfile(gt_path,flist(1).name);
end

fpn = fopen (gt_path, 'r');           %���ĵ� 

id=0;
while (~feof(fpn) )
    id=id+1;
    dataset.groundTruth{id} = str2num(fgetl(fpn));
end
end