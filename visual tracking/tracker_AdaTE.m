%%  Copyright all Reserved by the Author and the Institution
%%  Author: William Li
%%  Email:  WilliamLi_Pro@163.com

function result=tracker_AdaTE(tracker,dataset,camPara,priDist,drawresult)
%   Visual tracker with the method of adaptive trajectory estimation
% . The observation for tracking is the result of fDSST
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

% �˲�������ֵ
n=dataset.imageNumber;  %ʱ����
time=[1:n+1];

As=cell(n,1);
Qs=cell(n,1);

Rc=diag([1,1,0.25]);	%��ǰ����

H=[eye(3),zeros(3,6)];  %�۲����

sitar.Da=10*eye(3);
% sitar.Dt=0.5*eye(3,3);
% sitar.Dt(2,2)=0.5;
% sitar.Dt(3,3)=0.1;
sitar.alpha=0.01;
sitar.beta=0.2;
cut_t=1;

oao_traj=zeros(9,n);       %�켣
oao_traj_plane=zeros(n,4);  %ƽ��켣

mtraj_overlap=ones(1,n);    %�켣�ص���
oao_traj_RMSE=zeros(1,n);   %�켣RMSE

dX=zeros(9,n);

%%  ��һ֡ͼ��
% ��������ʼ��
pa=groundTruth{1};  % λ�ó�ֵ
width=(pa(2)-pa(1))*priDist/camPara.fx; %Ŀ����
rate=(pa(4)-pa(3))/(pa(2)-pa(1));       %�߿��
pos=[(pa(3)+pa(4))/2,(pa(1)+pa(2))/2];  %��������
pc=planeToCamCood(camPara,pa,width);    %����ת������ƽ��ͶӰ->�������ϵ

oao_traj_plane(1,:)=pa;     %ƽ��λ�ó�ֵ
oao_traj(1:3,1)=pc(1:3)';oao_traj(4:6,1)=[0;0;0];  %�켣��ֵ

dx=sqrt(Rc(1,1));dy=sqrt(Rc(2,2));dz=sqrt(Rc(3,3));
seach_r=camCoodtoPlane(camPara,[pc(1:3),dx*4+1],dy/dx); %������Χ��2����׼��
seach_r=[seach_r,(pc(3)-dz)/pc(3),(pc(3)+dz)/pc(3)];    %���ϳߴ�仯

tracker.frame=1;
tracker=tracker.update(tracker,images{1},pos);  %��������ʼ��
[tracker,pos]=tracker.estimate(tracker,images{i},pos);

% �۲�ֵ������
ob_size=size(tracker.observe,1);    %�۲����
obs=zeros(3,n,ob_size);
Rzs_ob=cell(n,ob_size);     %��������(�۲�����)
Rzs=cell(n,ob_size);        %��������(�˲�У��)

for j=1:ob_size
    cam_ob=planeToCamCood(camPara,tracker.observe(j,:),width);
    obs(:,1,j)=pc(1:3);
end
[~,~,Rzs_ob(1,:)]=observeCov(obs(:,1,:),tracker.obScore,Rc);
Rzs(1,:)=Rzs_ob(1,:);

i=1;    %״̬��ʼ��
[As(1:i),Qs(1:i),Rzs(1:i,:),cut_t,oao_traj(:,1:i),dX(:,1:i),~]=AdaTEAcc(As(1:i-1),Qs(1:i-1),Rzs_ob(1:i,:),Rzs(1:i,:),H,cut_t,oao_traj(:,1:i-1),dX(:,1:i-1),obs(:,1:i,:),sitar,time);

%%  ��������
for i=2:n
    tracker.frame=i;
    
    % Ԥ��
    dt=time(i+1)-time(i);
%     pre_x=AMLpredictACC(mlf_traj(:,i-1),alpha,dt);
%     pa=camCoodtoPlane(camPara,[pre_x(1:3)',width],rate);
%     pos=[(pa(3)+pa(4))/2,(pa(1)+pa(2))/2];  %��������
    
    % ���ٹ۲�
%     dx=sqrt(Rc(1,1));dy=sqrt(Rc(2,2));dz=sqrt(Rc(3,3));
%     seach_r(1:4)=camCoodtoPlane(camPara,[pre_x(1:3)',dx*4+1],dy/dx);  %������Χ��4����׼��
%     seach_r(5:6)=[(pre_x(3)-dz)/pre_x(3),(pre_x(3)+dz)/pre_x(3)];  %���ϳߴ�仯
    [tracker,pos]=tracker.estimate(tracker,images{i},pos);  %�������۲����
    
    n_ob=size(tracker.observe,1);
    for j=1:n_ob
        cam_ob=planeToCamCood(camPara,tracker.observe(j,:),width);
        obs(:,i,j)=cam_ob(1:3)';
    end
    [~,~,Rzs_ob(i,:)]=observeCov(obs(:,i,:),tracker.obScore,Rc);
    Rzs(i,:)=Rzs_ob(i,:);
    
    % �˲�У��
    [As(1:i),Qs(1:i),Rzs(1:i,:),cut_t,oao_traj(:,1:i),dX(:,1:i),~]=AdaTEAcc(As(1:i-1),Qs(1:i-1),Rzs_ob(1:i,:),Rzs(1:i,:),H,cut_t,oao_traj(:,1:i-1),dX(:,1:i-1),obs(:,1:i,:),sitar,time);
    
    % ����ת��
    for j=1:i
        oao_traj_plane(j,:)=camCoodtoPlane(camPara,[oao_traj(1:3,j)',width],rate);
    end
    tracker=tracker.update(tracker,images{i},pos);
%     disp(pos);
    
    % ͳ���������
    sum_e_traj=0;
    for j=1:i
        e_traj=oao_traj_plane(j,1:4)-groundTruth{j};
        ex=mean(e_traj(1:2));
        ey=mean(e_traj(3:4));
        sum_e_traj=sum_e_traj+ex^2+ey^2;
    end

    oao_traj_RMSE(i)=sqrt(sum_e_traj/i);
    
    % ͳ���ص���
    sum_overlap_traj=0; %�켣�ص���֮��
    for j=1:i
        cur_overlap=overlap(oao_traj_plane(j,1:4),groundTruth{j});
        sum_overlap_traj=sum_overlap_traj+cur_overlap;
    end
    mtraj_overlap(i)=sum_overlap_traj/i;    %�켣ƽ���ص���
    
%     sum_overlap_rt=sum_overlap_rt+cur_overlap;
%     mrt_overlap(i)=sum_overlap_rt/i;        %ʵʱƽ���ص���
    
    % ��ͼ
    [im_rows,im_cols,~]=size(images{i});
    if(drawresult)
        drawTrackResult(images{i},oao_traj(:,1:i),oao_traj_plane(i,:),camPara,1,0,im_cols,0,im_rows,0);
    end
    
    if(mod(i,10)==0)
        disp(['Current image: ',int2str(i)]);
    end
end

%   ������
result.trajectory=oao_traj_plane;       %���
result.TrajectoryError=oao_traj_RMSE;   %�������RMSE
result.TrajectoryOverlap=mtraj_overlap; %ƽ���ص���
end

