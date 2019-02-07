%EKF-RTS for trajectory estimation
%
%input:
% observation:obs
% observe matrix:H,
% covariance of observation: Rzs_ob
% state covariance at biginning: Qs,
% transition covariance: Qt,
% previous estimation: Xs,
% real time localization: Xs_real,
% some other parameters: palpha,pbeta,time,cut_t,dynamic
%
%output:
% updated trajectory: Xs_up
% updated covariances: Qs_up

function [Xs,Qs]=EKF_RTS(Zs,H,Rzs,Qs,Qt,Xs,Xs_real,palpha,pbeta,time,cut_t,choose)

[mx,nx]=size(Xs_real);
nz=size(Zs,2);
cur_t=nx+1;

if(nz<=nx)
    disp('error:�۲���Ϣ���㣬�޷�����˲�������۲���Ϣ');
    return;
end

% �����ڶ���۲⣬У���۲�
lz=size(Rzs,2);

if(lz>1)    %�۲���������1����ȡ��Ȩ��ֵ
    sinv_Rzs=zeros(size(Rzs{cur_t,1}));
    cur_z=zeros(length(Rzs{cur_t,1}),1);
    
    for j=1:lz
        inv_R=inv(Rzs{cur_t,j});
        sinv_Rzs=sinv_Rzs+inv_R;
        cur_z=cur_z+inv_R*Zs(:,cur_t,j);
    end
    
    Rz=inv(sinv_Rzs);
    cur_z=sinv_Rzs\cur_z;
else
    Rz=Rzs{cur_t,1};
    cur_z=Zs(:,cur_t,1);
end

% 1.kalman�˲��������һ��״̬
Xs=[Xs,zeros(mx,1)];
Qs=[Qs;cell(1)];
[Xs(:,cur_t),Qs{cur_t}]=ExtendedKalmanFilter(cur_z,H,Rz,Qt,Xs_real(:,nx),Qs{nx},palpha,pbeta,time(cur_t)-time(nx),choose);

% 2.RTSƽ������֮ǰ״̬
As=cell(nx,1);
if(choose=='Acc')	%���ٶ�ģ��
    for i=cut_t:nx
        dt=time(i+1)-time(i);
        As{i}=accModel(Xs(:,i),pbeta,dt);
    end
else
    for i=cut_t:nx
        dt=time(i+1)-time(i);
        As{i}=DPTmodel2(Xs(:,i),palpha,pbeta,dt);
    end
end

Xs=RTSsmoother(Xs,Xs_real,As,Qt,Qs,cut_t);

end

%% EKF�˲���
function [x_ev,Q_ev]=ExtendedKalmanFilter(z,H,Rz,Qt,x_pre,Q_pre,palpha,pbeta,dt,choose)
% ״̬ת��
if(choose=='Acc')   %���ٶ�ģ��
    Fy=accModel(x_pre,pbeta,dt);
else
    Fy=DPTmodel2(x_pre,palpha,pbeta,dt);
end

% Ԥ��
x_ev=Fy*x_pre;
Q_ev=Fy*Q_pre*Fy'+Qt;

% У��
K=Q_ev*H'/(H*Q_ev*H'+Rz);
x_ev=x_ev+K*(z-H*x_ev);
Q_ev=Q_ev-K*(H*Q_ev);
end

%% RTSƽ����
function Xs=RTSsmoother(Xs,Xs_real,As,Qt,Qs,cut_t)
%  ���룺״̬�켣Xs ʵʱ����Xs_real ״̬Ư��mrs ״̬ת��As ת�Ʒ���Qt ״̬����Qs �ض�ʱ��cut_t
[~,nx]=size(Xs);

for i=nx-1:-1:cut_t
    % Ԥ��ֵ
    A=As{i};
    x_pre=A*Xs_real(:,i);
    P=Qs{i};
    Q_pre=A*P*A'+Qt;
    
    % ����У��
    K=P*A'/Q_pre;
    Xs(:,i)=Xs_real(:,i)+K*(Xs(:,i+1)-x_pre);
end

end

%% �˶�ģ��
% Acc model
function Fy=accModel(x,pbeta,dt)
n=length(x);
Fy=eye(n);

% �ٶ�->λ��
for i=1:3
    Fy(i,i+3)=dt;
    Fy(i,i+6)=dt^2/2;
end

% ���ٶ�->�ٶ� ������
for i=4:6
    Fy(i,i+3)=dt;
    Fy(i,i)=Fy(i,i)-pbeta*dt;
end
end

%DPT model
function Fy=DPTmodel(x,palpha,pbeta,dt)
%����׼��
n=length(x);
Fy=eye(n,n);

%�ٶ�
v=x(4:6);   %�ٶȷ���
va=sqrt(v'*v);
if va<0.00001
    va=0.00001;
end

%����
w=x(7);
if w<-pbeta^2/(4*palpha);
    w=0.000001-pbeta^2/(4*palpha);
end

%������һʱ���ٶ�
sqt_baw=sqrt(pbeta^2+4*palpha*w);
r=pbeta/sqt_baw;
kesy1=(pbeta+sqt_baw)/(2*palpha);
kesy2=-2*w/(pbeta+sqt_baw);

va_n=va;
f2=(1+r)*log(abs(va+kesy1))+(1-r)*log(abs(va+kesy2))-2*palpha*dt;  %ǰһʱ��ϵ��
for iter=1:10
    f1=(1+r)*log(abs(va_n+kesy1))+(1-r)*log(abs(va_n+kesy2));
    f=f1-f2;
    df=(1+r)/(va_n+kesy1)+(1-r)/(va_n+kesy2);
    
    rt=abs(va_n/kesy2);
    if rt>1
        rt=1/rt;
    end
    
    va_n=va_n-rt*f/df;
end

if va_n<0
    va_n=-va_n;
end

%��������
exp_ra=exp(-2*palpha*dt/(1-r));
exp_ra1=(1-exp_ra)/(2*palpha/(1-r));

hk=abs((va_n+kesy1)/(va+kesy1))^(-(1+r)/(1-r));
gk=2/(pbeta+sqt_baw)*(1-exp_ra*hk);
gk1=2/(pbeta+sqt_baw)*(dt-exp_ra1*hk);

%�������
vx=zeros(3,3);%�������
vx(1,2)=-v(3); vx(1,3)=v(2);
vx(2,1)=v(3);  vx(2,3)=-v(1);
vx(3,1)=-v(2); vx(3,2)=v(1);

Fy(1:3,4:6)=eye(3)*(exp_ra1*hk);
Fy(1:3,7)=gk1*v/va;
Fy(1:3,8:10)=-(exp_ra1*hk+gk1*w/va)*dt*vx;
Fy(4:6,4:6)=eye(3)*(exp_ra*hk);
Fy(4:6,7)=gk*v/va;
Fy(4:6,8:10)=-(exp_ra*hk+gk*w/va)*dt*vx;

end

function Fy=DPTmodel2(x,palpha,pbeta,dt)
%����׼��
n=length(x);
Fy=eye(n,n);

%�ٶ�
v=x(4:6);   %�ٶȷ���
va=sqrt(v'*v);
if va<0.001
    va=0.001;
end

%����
w=x(7);

%�����ٶȲ���
exp_at=exp(-palpha*dt);
exp_at1=(1-exp_at)/palpha;
exp_at2=(dt-exp_at1)/palpha;

gk=exp_at-pbeta/va*exp_at1;
gk1=exp_at1-pbeta/va*exp_at2;
hk=exp_at1/(va^2+dt*w/4);
hk1=exp_at2/(va^2+dt*w/4);
fiyk=dt*(gk+hk*w);
fiyk1=dt*(gk1+hk1*w);

%�������
vx=zeros(3,3);%�������
vx(1,2)=-v(3); vx(1,3)=v(2);
vx(2,1)=v(3);  vx(2,3)=-v(1);
vx(3,1)=-v(2); vx(3,2)=v(1);

Fy(1:3,4:6)=eye(3)*gk1;
Fy(1:3,7)=hk1*v;
Fy(1:3,8:10)=-fiyk1*vx;
Fy(4:6,4:6)=eye(3)*gk;
Fy(4:6,7)=hk*v;
Fy(4:6,8:10)=-fiyk*vx;

end