%%  Copyright all Reserved by the Author and the Institution
%%  Author: William Li
%%  Email:  WilliamLi_Pro@163.com

function result=trackerRun(tracker,dataset,camPara,priDist,drawresult)
%   Visual tracker with the method correlation filter and
%
%
%   Input:
%   - tracker (structure): A visual tracker with multi-observations
%   - dataset (cell or structure): Sequence images of dataset and the ground truth 
%   - camPara (structure): Parameters of camPara, include (cx, cy, fx, fy)
%   - priDist (array): The primary distance of object, usually set 100
%
%   Output
%   - result (structure): The result of experiment, include the result of:
%   online filter, trajectory and their RMSE/

if(isempty(drawresult)) %Ĭ�ϲ���ͼ
    drawresult=0;
end

if(isempty(tracker))
    error('No tracker available ') ;
end
if(isempty(dataset))
    error('No dataset available ') ;
end

% �������ݼ���켣��ֵ
images=cell(dataset.imageNumber,1);
for i=1:dataset.imageNumber
    images{i}=imread(dataset.imagePath{i});
end

groundTruth=cell(dataset.imageNumber,1);

for i=1:dataset.imageNumber
    cur_R=dataset.groundTruth{i};   %������Χ��Ϊ (x_min,x_max,y_min,y_max) ��ʽ
    switch(dataset.gtType)
        case 'VOT'
            ys=sort([cur_R(2),cur_R(4),cur_R(6),cur_R(8)]);
            xs=sort([cur_R(1),cur_R(3),cur_R(5),cur_R(7)]);
            groundTruth{i}=[mean(xs(1:2)),mean(xs(3:4)),mean(ys(1:2)),mean(ys(3:4))];
        case 'XYrange'
            groundTruth{i}=[cur_R(1),cur_R(2),cur_R(3),cur_R(4)];
        case 'YXrange'
            groundTruth{i}=[cur_R(3),cur_R(4),cur_R(1),cur_R(2)];
        case 'points xy'
            x_min=min([cur_R(1),cur_R(3)]);
            x_max=max([cur_R(1),cur_R(3)]);
            y_min=min([cur_R(2),cur_R(4)]);
            y_max=max([cur_R(2),cur_R(4)]);
            groundTruth{i}=[x_min,x_max,y_min,y_max];
        case 'points yx'
            x_min=min([cur_R(2),cur_R(4)]);
            x_max=max([cur_R(2),cur_R(4)]);
            y_min=min([cur_R(1),cur_R(3)]);
            y_max=max([cur_R(1),cur_R(3)]);
            groundTruth{i}=[x_min,x_max,y_min,y_max];
        case 'x-w-y-h'  % ���Ͻ�x-���-���Ͻ�y-�߶�
            groundTruth{i}=[cur_R(1),cur_R(1)+cur_R(2),cur_R(3),cur_R(3)+cur_R(4)];
        case 'x-y-w-h'  % ���Ͻ�x-���Ͻ�y-���-�߶�
            groundTruth{i}=[cur_R(1),cur_R(1)+cur_R(3),cur_R(2),cur_R(2)+cur_R(4)];
        otherwise
            error('Form of ground truth is not available ') ;
    end
end

%% ���������ʼ��
n=dataset.imageNumber;  %ʱ����
mlf_traj_plane=zeros(n,4);  %ƽ��켣
mlf_rt_plane=zeros(n,4);    %ƽ��ʵʱ

mtraj_overlap=ones(1,n);    %�켣�ص���
mrt_overlap=ones(1,n);      %ʵʱ�ص���
mlf_traj_RMSE=zeros(1,n);   %�켣RMSE
mlf_rt_RMSE=zeros(1,n);     %ʵʱRMSE

%% ��������ʼ��
tracker.frame=1;
pa=groundTruth{1};  % λ�ó�ֵ
mlf_rt_plane(1,:)=pa;       %ƽ��λ�ó�ֵ
mlf_traj_plane(1,:)=pa;     %ƽ��λ�ó�ֵ

pos=[(pa(3)+pa(4))/2,(pa(1)+pa(2))/2];  %��������
tracker=tracker.update(tracker,images{1},pos);  %��������ʼ��
[tracker,pos]=tracker.estimate(tracker,images{i},pos);

%%  ��������
sum_e_rt=0;         %ʵʱ���֮��
sum_overlap_rt=1;   %ʵʱ�����ص���֮��

for i=2:n
    tracker.frame=i;
    [tracker,pos]=tracker.estimate(tracker,images{i},pos);  %�������۲����
    tracker=tracker.update(tracker,images{i},pos);  %��������������
    
%     disp(pos);

    % ����ת��
    cur_sz=tracker.target_sz;
    cur_box=[pos(2)-floor((cur_sz(2)-1)/2),pos(2)-floor((cur_sz(2)-1)/2)+cur_sz(2)-1,pos(1)-floor((cur_sz(1)-1)/2),pos(1)-floor((cur_sz(1)-1)/2)+cur_sz(1)-1];

    mlf_traj_plane(i,:)=cur_box;
    mlf_rt_plane(i,:)=cur_box;

    % ͳ���������
    sum_e_traj=0;
    for j=1:i
        e_traj=mlf_traj_plane(j,1:4)-groundTruth{j};
        ex=mean(e_traj(1:2));
        ey=mean(e_traj(3:4));
        sum_e_traj=sum_e_traj+ex^2+ey^2;
    end
    mlf_traj_RMSE(i)=sqrt(sum_e_traj/i);
    sum_e_rt=sum_e_rt+ex^2+ey^2;
    mlf_rt_RMSE(i)=sqrt(sum_e_rt/i);
    
    % ͳ���ص���
    sum_overlap_traj=0; %�켣�ص���֮��
    for j=1:i
        cur_overlap=overlap(mlf_traj_plane(j,1:4),groundTruth{j});
        sum_overlap_traj=sum_overlap_traj+cur_overlap;
    end
    mtraj_overlap(i)=sum_overlap_traj/i;    %�켣ƽ���ص���
    
%     sum_overlap_rt=sum_overlap_rt+cur_overlap;
%     mrt_overlap(i)=sum_overlap_rt/i;        %ʵʱƽ���ص���
    mrt_overlap(i)=cur_overlap;
    
    % ��ͼ
    [im_rows,im_cols]=size(images{i});
    if(drawresult)
        drawTrackResult(images{i},[],mlf_rt_plane(i,:),camPara,1,0,im_cols,0,im_rows,0);
    end
    if(mod(i,10)==0)
        disp(['Current image: ',int2str(i)]);
    end
end
%   ������
result.trajectory=mlf_traj_plane;       %���
result.TrajectoryError=mlf_traj_RMSE;   %�������RMSE
result.TrajectoryOverlap=mtraj_overlap; %ƽ���ص���
end