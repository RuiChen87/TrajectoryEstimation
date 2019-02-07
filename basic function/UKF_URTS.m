%UKF-URTS for trajectory estimation
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

function [Xs,Qs]=UKF_URTS(Zs,H,Rzs,Qs,Qt,Xs,Xs_real,palpha,pbeta,time,cut_t,dynamic)

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

% 1.UKF�˲��������һ��״̬
Xs=[Xs,zeros(mx,1)];
Qs=[Qs;cell(1)];
[Xs(:,nx+1),Qs{nx+1}]=UnscentedKalmanFilter(cur_z,H,Rz,Qt,Xs(:,nx),Qs{nx},palpha,pbeta,time(nx+1)-time(nx),dynamic);

% 2.URTSƽ������֮ǰ״̬
Xs=URTSsmoother(Xs,Xs_real,Qt,Qs,palpha,pbeta,time,cut_t,dynamic);
end

%% UKF�˲���
function [x_ev,Q_ev]=UnscentedKalmanFilter(z,H,Rz,Qt,xk,Q_pre,palpha,pbeta,dt,choose)

% ��������
nx=length(xk);
a=1;
beita=3;
kap=5;
lambda=a^2*(nx+kap)-nx;
c=nx+lambda;

wm=ones(nx*2+1,1)/(2*c);  %Ȩ��
wm(nx*2+1)=lambda/c;    %��ֵȨ��
wc=wm;  %Ȩ��
wc(nx*2+1)=lambda/c+1-a^2+beita; %��ֵȨ��

% 1.kʱ��Sigma����
xk_sigma=zeros(nx,2*nx+1);
root_Q=sqrtm(c*Q_pre);

for i=1:nx
    xk_sigma(:,i)=xk+root_Q(:,i);
    xk_sigma(:,nx+i)=xk-root_Q(:,i);
end
xk_sigma(:,nx*2+1)=xk;

% 2.����״̬ת��Ԥ��
x_predict=zeros(nx,2*nx+1);
if(choose=='Acc')   %���ٶ�ģ��
    for i=1:2*nx+1
        x_predict(:,i)=accModel(xk_sigma(:,i),pbeta,dt);
    end
else            %����ģ��
    for i=1:2*nx+1
        x_predict(:,i)=DPTmodel2(xk_sigma(:,i),palpha,pbeta,dt);
    end
end

% 3.����Ԥ��ת�ƾ�ֵ�뷽��
mx_pre=zeros(nx,1);
Px_pre=Qt;

for i=1:2*nx+1
    mx_pre=mx_pre+x_predict(:,i)*wm(i);
end

for i=1:2*nx+1
    dx=x_predict(:,i)-mx_pre;
    Px_pre=Px_pre+(wc(i)*dx)*dx';
end

% 4.Ԥ��ֵsigma����
root_Ppre=sqrtm(c*Px_pre);

for i=1:nx
    xk_sigma(:,i)=mx_pre+root_Ppre(:,i);
    xk_sigma(:,nx+i)=mx_pre-root_Ppre(:,i);
end
xk_sigma(:,nx*2+1)=mx_pre;

% 5.�����۲�Ԥ��
nz=length(z);
z_pre=zeros(nz,nx*2+1);
for i=1:nx*2+1
    z_pre(:,i)=H*xk_sigma(:,i);
end

mz_pre=zeros(nz,1);
Sz=Rz;  %�۲ⷽ�����ת�Ʒ���
Cxz=zeros(nx,nz);
for i=1:nx*2+1
    mz_pre=mz_pre+z_pre(:,i)*wm(i);
end

for i=1:nx*2+1
    dx=x_predict(:,i)-mx_pre;
    dz=z_pre(:,i)-mz_pre;
    
    Sz=Sz+(wc(i)*dz)*dz';
    Cxz=Cxz+(wc(i)*dx)*dz';
end

% 6.״̬У��
Ka=Cxz/Sz;
x_ev=mx_pre+Ka*(z-mz_pre);
Q_ev=Px_pre-Ka*Cxz';    %Ka*Sz*Ka'=Ka*Sz*(Cxz/Sz)'=Ka*Cxz'
end

%% URTSƽ����
function Xs=URTSsmoother(Xs,Xs_real,Qt,Qs,palpha,pbeta,time,cut_t,choose)
[L,nx]=size(Xs);

% ��������
a=1;
beita=3;
kap=5;
lambda=a^2*(L+kap)-L;
c=L+lambda;

wm=ones(L*2+1,1)/(2*c);  %Ȩ��
wm(L*2+1)=lambda/c;    %��ֵȨ��
wc=wm;  %Ȩ��
wc(L*2+1)=lambda/c+1-a^2+beita; %��ֵȨ��

% �˲�
xk_sigma=zeros(L,2*L+1);
x_predict=zeros(L,2*L+1);

for i=nx-1:-1:cut_t
    dt=time(i+1)-time(i);
    
    % 1.sigma����
    root_Q=sqrtm(c*Qs{i});
    xk=Xs_real(:,i);
    
    for j=1:L
        xk_sigma(:,j)=xk+root_Q(:,j);
        xk_sigma(:,L+j)=xk-root_Q(:,j);
    end
    xk_sigma(:,L*2+1)=xk;
    
    % 2.����״̬ת��Ԥ��
    if(choose=='Acc')   %���ٶ�ģ��
        for j=1:2*L+1
            x_predict(:,j)=accModel(xk_sigma(:,j),pbeta,dt);
        end
    else            %����ģ��
        for j=1:2*L+1
            x_predict(:,j)=DPTmodel2(xk_sigma(:,j),palpha,pbeta,dt);
        end
    end
    
    % 3.����Ԥ��ת�ƾ�ֵ�뷽��
    mx_pre=zeros(L,1);  %Ԥ���ֵ
    Px_pre=Qt;          %Ԥ�ⷽ��
    Cx_pre=zeros(L,L);  %Ԥ��Э����
    
    for j=1:2*L+1
        mx_pre=mx_pre+x_predict(:,j)*wm(j);
    end

    for j=1:2*L+1
        dx=x_predict(:,j)-mx_pre;
        dx_k=xk_sigma(:,j)-xk;
        
        Px_pre=Px_pre+(wc(j)*dx)*dx';
        Cx_pre=Cx_pre+(wc(j)*dx_k)*dx';
    end
    
    % 4.ƽ��У��
    Xs(:,i)=xk+Cx_pre*(Px_pre\(Xs(:,i+1)-mx_pre));
end
end

%% �˶�ģ��
% ���ٶ�ģ��
function x_new=accModel(x,pbeta,dt)
x_new=x;

% �ٶ�->λ��
dt_2=dt^2/2;
x_new(1:3)=x_new(1:3)+(dt-pbeta*dt_2)*x(4:6)+dt_2*x(7:9);

% ���ٶ�->�ٶ� ������
x_new(4:6)=(1-pbeta*dt)*x(4:6)+dt*x(7:9);
end

% ����ģ��
function x_new=DPTmodel(x,palpha,pbeta,dt)
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
if abs(w)<0.001
    w=w/abs(w)*0.001;
end
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

x_new=Fy*x;
end

function x_new=DPTmodel2(x,palpha,pbeta,dt)
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

%�������
ct=x(8:10);
cx=zeros(3,3);%�������
cx(1,2)=-ct(3); cx(1,3)=ct(2);
cx(2,1)=ct(3);  cx(2,3)=-ct(1);
cx(3,1)=-ct(2); cx(3,2)=ct(1);

vn=(exp_at+exp_at1*(w/va^2-pbeta/va))*expm(dt*cx)*v;
pn=x(1:3)+dt*(v+vn)/2;

x_new=[pn;vn;x(7:10)];
end
