%%  ����ת�����������ƽ��ͶӰ->�������ϵ
%   ����һ��ģ����������������ǻ��䲹��
%   ���룺
%   ����������� camera (��������������� camera.cx camera.cy ������� camera.fx camera.fy)
%   �������ƽ��λ�� pp=[u1,u2,v1,v2]
%   ������ w

%   �����
%   �������ϵλ�� pc=[x,y,w,h]

function pc=planeToCamCood(camera,pp,w)
pc=zeros(1,4);

d=abs(w*camera.fx/(pp(2)-pp(1)));

pc(1)=((pp(1)+pp(2))/2-camera.cx)*d/camera.fx;  %x
pc(2)=((pp(3)+pp(4))/2-camera.cy)*d/camera.fy;  %y
pc(3)=d;                                        %d
pc(4)=w;                                        %w

end