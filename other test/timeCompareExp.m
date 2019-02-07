%% test of time
% compare the time consumption of sparse MAP and OAO

%%  ���·��
cd('E:\��������ʶ��\���Ĺ���\���ڶ�ģ̬�ںϵ�Ŀ�����\����\ʵ��20180926\����ʵ��');
addpath('../��������');

%%  �켣����
nz=1;
Rz=diag([18,16,5]);
[real,obs,time]=eightTraj(nz,Rz,300,500,0);

x_min=min(real(1,:));x_max=max(real(1,:));
y_min=min(real(2,:));y_max=max(real(2,:));

x_range=(x_max-x_min)/8;
y_range=(y_max-y_min)/8;
if(x_range>y_range) %��ͼ��䷽
    y_range=5*x_range-4*y_range;
else
    x_range=5*y_range-4*x_range;
end

x_min=x_min-x_range;x_max=x_max+x_range;
y_min=y_min-y_range;y_max=y_max+y_range;

%%  ������ֵ
n=length(time);

As=cell(n,1);
Qs=cell(n,1);

Rzs_ob=cell(n,nz);
for i=1:n
    for j=1:nz
        Rzs_ob{i,j}=Rz;
    end
end
Rzs=Rzs_ob;      %���㷽��
H=[eye(3),zeros(3,7)];

%% OAO
sitar.Da=0.0002;
sitar.Dt=0.0001*eye(3,3);
sitar.Dt(2,2)=0.0001;
sitar.Dt(3,3)=0.0001;
sitar.alpha=0.02;
sitar.beta=0.5;

OAO_traj=zeros(10,n);       %�켣
OAO_time=zeros(1,n);

dX=zeros(10,n);
cut_t=0;

for i=1:n
    % �˲�
    tic;
    [As(1:i),Qs(1:i),Rzs(1:i,:),cut_t,OAO_traj(:,1:i),dX(:,1:i),preX]=OAOestimation(As(1:i-1),Qs(1:i-1),Rzs_ob(1:i,:),Rzs(1:i,:),H,cut_t,OAO_traj(:,1:i-1),dX(:,1:i-1),obs(:,1:i,:),sitar,time);
    OAO_time(i)=toc;
    
%      drawTrajectory(OAO_traj(1:3,1:i),1,x_min,x_max,y_min,y_max); %�켣ͼ
%      drawObserve(obs(1:3,1:i,:),2,x_min,x_max,y_min,y_max);%�۲�ͼ
end
figure(1);
plot(OAO_time*1000);
xlabel('k');
ylabel('ms');

%%  ��������˲������ߣ�
sitar.Da=0.0002;
sitar.Dt=0.0001*eye(3,3);
sitar.Dt(2,2)=0.00015;
sitar.Dt(3,3)=0.00008;

MAP_traj=zeros(14,n);       %�켣
MAP_time=zeros(1,n);

for i=1:n
    % �˲�
    tic;
    MAP_traj(:,1:i)=MAPestimation(MAP_traj(:,1:i),obs(:,1:i,1),Rzs_ob(1:i,1),sitar,time);
    MAP_time(i)=toc;
    
%     drawTrajectory(MAP_traj(1:3,1:i),1,x_min,x_max,y_min,y_max); %�켣ͼ
%     drawObserve(obs(1:3,1:i,:),2,x_min,x_max,y_min,y_max);%�۲�ͼ
end
figure(2);
plot(MAP_time*1000);
xlabel('k');
ylabel('ms');

%%  �Ա�
figure(3);
hold off;
plot(time,OAO_time*1000,'Color',[1,0.5,0.1]);hold on;
plot(time,MAP_time*1000,'Color',[0.1,0.6,1]);
legend('OAO-DPT','MAP-CT');
xlabel('k');
ylabel('ms');