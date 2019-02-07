%% some statistics about OAO
%present the change of transition covariance and observation covariance in OAO

%%  ���·��
cd('E:\��������ʶ��\���Ĺ���\���ڶ�ģ̬�ںϵ�Ŀ�����\����\ʵ��20180926\����ʵ��');
addpath('../��������');

%% �켣���� for state statistics
nz=1;
Rz=diag([1,1,1]);

n=40;
time=[1:n];
real=zeros(3,n);

% 1.���ɹ켣��ֵ
% ֱ��
for i=1:n
    real(1,i)=i;
    real(2,i)=0;
end

% 2.�۲�ֵ
obs=zeros(3,n);
root_Rz=sqrtm(Rz);
for i=1:n
    obs(:,i)=real(:,i)+root_Rz*(rand(3,1)-0.5);
end

%%  ������ֵ
As=cell(n,1);
Qs=cell(n,1);

Rzs_ob=cell(n,1);
Rzu=Rz/16;
for i=1:n
    Rzs_ob{i}=Rzu;
end
Rzs=Rzs_ob;      %���㷽��
H=[eye(3),zeros(3,7)];

%%  ��γ�ʼ�����Ե�һʱ�̲���
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

sp_n=500;
sp.x30=zeros(10,sp_n);
sp.x31=zeros(10,sp_n);
sp.dx=zeros(10,sp_n);

for s=1:sp_n
    for i=1:n
        % �˲�
        [As(1:i),Qs(1:i),Rzs(1:i,:),cut_t,OAO_traj(:,1:i),dX(:,1:i),preX]=OAOestimation(As(1:i-1),Qs(1:i-1),Rzs_ob(1:i,:),Rzs(1:i,:),H,cut_t,OAO_traj(:,1:i-1),dX(:,1:i-1),obs(:,1:i,:),sitar,time);
    end
    
    sp.x30(:,s)=OAO_traj(:,30);
    sp.x31(:,s)=OAO_traj(:,31);
    sp.dx(:,s)=dX(:,30);
    
    disp(['iteration: ',num2str(s)]);
end

%%  ��ͼ
figure(11);
plot3(sp.x30(1,:),sp.x30(2,:),sp.x30(3,:),'c.','MarkerSize',3);
axis([29.8,30.2,-0.2,0.2,-0.2,0.2]);

figure(12);
plot3(sp.x31(1,:),sp.x31(2,:),sp.x31(3,:),'c.','MarkerSize',3);
axis([30.8,31.2,-0.2,0.2,-0.2,0.2]);

figure(13);
plot3(sp.dx(1,:),sp.dx(2,:),sp.dx(3,:),'c.','MarkerSize',3);
axis([-0.001,0.001,-0.001,0.001,-0.001,0.001]);

u_sp=mean(sp.dx,2);
t_cov=zeros(3,3);
for i=1:sp_n
    dd=sp.dx(:,i)-u_sp;
    t_cov=t_cov+dd*dd';
end
t_cov=t_cov/sp_n;


%%  �۲����
sp_obs=zeros(3,sp_n);
for i=1:sp_n
    sp_obs(:,i)=root_Rz*randn(3,1)/4;
end

figure(14);
plot3(sp_obs(1,:),sp_obs(2,:),sp_obs(3,:),'c.','MarkerSize',3);
axis([-2,2,-2,2,-2,2]);