% ����sparse MAP �Ĺ켣���ƺ���

function x_new=MAPestimation(x_old,p_ob,p_Qz,sitar,time)
    %��ʼֵ
    if size(x_old,2)<10
        x_old=initializeX(p_ob,x_old,time);
        if size(x_old,2)<6
            x_new=x_old;
            return;
        end
    end
    
    %����ϵ����������
    [M,b]=factorMatrixAndVector(x_old,p_ob,p_Qz,sitar,time);
    
    %���ݹ۲�ֵУ���켣
    x_new=reviseTrackformObserve(M,b);
end

%%  ��ʼ���켣
function x=initializeX(p_ob,x,time)
[~,n_ob,lz]=size(p_ob);
for i=1:n_ob
    cur_ob=p_ob(:,i,1);
    for j=2:lz
        cur_ob=cur_ob+p_ob(:,i,j);
    end
    x(1:3,i)=cur_ob/lz;
    
    if i<n_ob
        x(4:6,i)=(x(1:3,i+1)-x(1:3,i))/(time(i+1)-time(i));
    end
    x(:,i)=x(:,i)+0.2*rand(14,1)-0.1;
end

end

%%	����ϵ����������
function [M,b]=factorMatrixAndVector(track,ob_z,Qzs,sitar,time)
%���룺track״̬�켣,ob_z�۲�����,Qz�۲ⷽ��,sitar�������

n=size(track,2);%״̬����
lz=size(ob_z,3);%ͬʱ�۲����

% (1)״̬ת�ƾ���
As=cell(n,1);

for i=1:n-1
    dt=time(i+1)-time(i);
    
    trans_state=track(:,i);
    cr_A=stateTransform(trans_state,dt);
    
    As{i}.mat=cr_A;
end

% (2)Qz״̬ת�Ʒ���,Qt�۲ⷽ�����
H=zeros(3,14);
for i=1:3
    H(i,i)=1;
end

Qt_inv=cell(n,1);
Qz_inv=cell(n,lz);

strength_q=0;  %��һ���۲�����ƽ��ǿ��
for i=1:3
    strength_q=strength_q+Qzs{1}(i,i);
end

for i=1:n
    for j=1:lz
        cur_Qz(:,:)=Qzs{i,j};
        
        if(cur_Qz(1,1)<0)
            cur_ivQz=zeros(3,3);
        else
            cur_ivQz=inv(cur_Qz);
        end
        
        Qz_inv{i,j}.mat=cur_ivQz;
    end
    
    if i==n
        break;
    end
    
    %Ԥ����һʱ��״̬����
    dt=time(i+1)-time(i);
    Q_tal=convTrans(track(:,i),sitar,dt);    %״̬ת������
    %cur_Qt=cur_A*cur_Qt*cur_A'+Q_tal;   %Ԥ�ⷽ��
    cur_Qt=Q_tal;
    cur_ivQt=inv(cur_Qt);
    
    Qt_inv{i}.mat=cur_ivQt;
end

% (3)ϵ������ĸ�������
M=cell(n,1);

% �Խ����ϵ��Ӿ���
sum_Qz=Qz_inv{1,1}.mat;
for j=2:lz
    sum_Qz=sum_Qz+Qz_inv{1,j}.mat;
end
M{1}.R_cross=H'*sum_Qz*H+As{1}.mat'*Qt_inv{1}.mat*As{1}.mat; %i==1


for i=2:n-1
    sum_Qz=Qz_inv{i,1}.mat;
    for j=2:lz
        sum_Qz=sum_Qz+Qz_inv{i,j}.mat;
    end
    M{i}.R_cross=H'*sum_Qz*H+As{i}.mat'*Qt_inv{i}.mat*As{i}.mat+Qt_inv{i-1}.mat; %2<=i<=n-1
end

sum_Qz=Qz_inv{n,1}.mat;
for j=2:lz
    sum_Qz=sum_Qz+Qz_inv{n,j}.mat;
end
M{n}.R_cross=H'*sum_Qz*H+Qt_inv{n-1}.mat; %i==n

% �ǶԽ����Ӿ���
for i=1:n-1
    M{i}.R_side=As{i}.mat'*Qt_inv{i}.mat;
end

% (4)�۲������ĸ�������
b=cell(n,1);
for i=1:n
    cur_z=Qz_inv{i,1}.mat*ob_z(:,i,1);
    for j=2:lz
        cur_z=cur_z+Qz_inv{i,j}.mat*ob_z(:,i,j);
    end
    b{i}.vec=H'*cur_z;
end

end

% ����״̬ת�ƾ���
function A=stateTransform(cur_s,dt)
A=eye(14,14);

% (1)λ������
for i=1:3
    A(i,i+3)=dt;
end

% (2)�ٶ�����
v=cur_s(4:6);
lv=sqrt(v'*v);   %�ٶȵ�ģ
if(lv>0)    
    v_dire=cur_s(4:6)/lv;   %�ٶȷ���
else
    v_dire=zeros(3,1);
end

v_cs=zeros(3,3);%���Գƾ���
v_cs(1,2)=-v(3); v_cs(1,3)=v(2);
v_cs(2,1)=v(3); v_cs(2,3)=-v(1);
v_cs(3,1)=-v(2); v_cs(3,2)=v(1);

%A(4:6,4:6)=A(4:6,4:6)-eye(3,3)*lv*0.0001*dt;  %0.0001Ϊ��������� F=p*v^2  a=p*v^2/m
A(4:6,7)=v_dire*dt;
A(4:6,8:10)=v_cs*dt;

% (3)���ٶ�����
A(7,11)=dt;

for i=8:10
    A(i,i+4)=dt;
end
end

%  ����״̬ת�Ʒ�����
function Tal=convTrans(state,sitar,dt)
Tal=zeros(14,14);
Da=sitar.Da;
Dt=sitar.Dt;

% (1)�ٶ�����
lv=sqrt(state(4:6)'*state(4:6));   %�ٶȵ�ģ
if(lv>0)    
    v_dire=state(4:6)/lv;   %�ٶȷ���
else
    v_dire=ones(3,1)*sqrt(1/3);
end

conv_v=v_dire*v_dire';
% λ��
%Tal(1:3,1:3)=conv_v*1+1*eye(3,3);
Tal(1:3,1:3)=conv_v+diag([1,1,1])*Da*dt^7/7;

% �ٶ�
%Tal(4:6,4:6)=conv_v*1+1*eye(3,3);
Tal(4:6,4:6)=conv_v+diag([1,1,1])*Da*dt^5/5;

% �������ٶ�
Tal(7,7)=Da*dt^3/3;
Tal(8:10,8:10)=Dt*dt^3/3;

% ���ٶȵĵ���
Tal(11,11)=dt*Da;
Tal(12:14,12:14)=dt*Dt;

end

%%  ���ݹ۲�ֵУ���켣
function track_r=reviseTrackformObserve(M,b)
n=length(M); %�������

% (1)��M��ÿ��������Cholesky�ֽ�
cross_T=cell(n,1);
side_R=cell(n-1,1);
Alta=cell(n,1); %�ԽǾ���

%tic;
[cross_T{1}.mat,Alta{1}.mat]=cholesky(M{1}.R_cross);
%toc;

for i=2:n
    cross_T_trans=cross_T{i-1}.mat';
    mid_mat=cross_T_trans\M{i-1}.R_side;
    side_R{i-1}.mat=mid_mat;
    for j=1:14
        side_R{i-1}.mat(j,:)=side_R{i-1}.mat(j,:)/Alta{i-1}.mat(j);
    end
    
    res_mat=M{i}.R_cross-mid_mat'*side_R{i-1}.mat;
    [cross_T{i}.mat,Alta{i}.mat]=cholesky(res_mat);
end

% (2)�������
%��һ����� Y=inv(Tal)*inv(U')*B
track_y=zeros(14,n);

for i=1:n
    cur_T=cross_T{i}.mat;
    cur_b=b{i}.vec;
    
    if(i>1)
        cur_R=side_R{i-1}.mat;
        last_x=track_y(:,i-1);
        
        cur_b=cur_b+cur_R'*last_x;
    end
    
    track_y(:,i)=cur_T'\cur_b;
end

for i=1:n
    cur_Alta=Alta{i}.mat;
    
    track_y(:,i)=track_y(:,i)./cur_Alta';
end

%��2����� X=inv(U)*Y
track_r=zeros(14,n);

for i=n:-1:1
    cur_T=cross_T{i}.mat;
    cur_y=track_y(:,i);
    
    if(i<n)
        cur_R=side_R{i}.mat;
        last_x=track_r(:,i+1);
        
        cur_y=cur_y+cur_R*last_x;
    end
    
    track_r(:,i)=cur_T\cur_y;
end

end

% �������������Գƾ���cholesky�ֽ�(��Ҫ�����Cholesky�ֽ�)
function [Up,Alta]=cholesky(mat)
[n,m]=size(mat);

if(m~=n)    %���󲻶Գ�
    Up=-1;
    return;
end

Up=zeros(n,n);
Alta=zeros(1,n);    %�ԽǾ���Ԫ��
for i=1:n
    %�Խ���
    sum_up=0;
    for j=1:i-1
        sum_up=sum_up+Up(j,i)*Up(j,i)*Alta(j);
    end
    Alta(i)=mat(i,i)-sum_up;
    Up(i,i)=1;
    
    %�ǶԽ���
    for j=i+1:n
        sum_up=0;
        for k=1:i-1
            sum_up=sum_up+Up(k,i)*Up(k,j)*Alta(k);
        end
        
        Up(i,j)=(mat(i,j)-sum_up)/Up(i,i)/Alta(i);
    end
end
end
