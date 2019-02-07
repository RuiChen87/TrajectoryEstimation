%%  �������ɺ���
%   ���ݸ����۲�ֵ��ƥ�����Ŷȼ���λ�þ�ֵ�����巽����ֲ�����
%   ���룺
%   �۲�λ�� obs
%   ƥ�����Ŷ� belief

%   �����
%   ����λ�� mp
%   ���巽�� Rc
%   �����۲ⷽ�� Rzs
function [mp,Rc,Rzs]=observeCov(obs,belief,Rc)
% �����ֵ
[m_ob,n_ob]=size(obs);
mp=zeros(m_ob,1);
s_blf=sum(belief);
% belief=belief/sum(belief);  %Ȩֵ��һ��

for i=1:n_ob
    mp=mp+obs(:,i)*belief(i);
end
mp=mp/s_blf;
% 
% % ����
% Rc=3*Rc+0.01*eye(3);    %��ֹ����
% for i=1:n_ob
%     dob=obs(:,i)-mp;
%     Rc=Rc+(belief(i)*dob)*dob';
% end
% thre=sum([Rc(1,1),Rc(2,2),Rc(3,3)])/9;
% for i=1:3
%     if(Rc(i,i)<thre)
%         Rc(i,i)=Rc(i,i)+thre;
%     else
%         if(Rc(i,i)>9*thre)
%             Rc(i,i)=Rc(i,i)-thre;
%         end
%     end
% end
% Rc=Rc/(s_blf*4);

% �ֲ�����
thre=-min([belief;0])+0.001;
Rzs=cell(1,n_ob);
for i=1:n_ob
    Rzs{i}=Rc/(belief(i)+thre); %��ֹ��ĸΪ0
end
end