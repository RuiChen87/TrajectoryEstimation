%%  ����ת����������������ϵ->��ƽ��ͶӰ
%   ����һ��ģ����������������ǻ��䲹��
%   ���룺
%   ����������� camera (��������������� camera.cx camera.cy ������� camera.fx camera.fy)
%   ����λ�ü���Χ pc=[x,y,d,w]
%   ����߿�� rate

%   �����
%   ��ƽ��λ�� pp=[u1,u2,v1,v2]

function pp=camCoodtoPlane(camera,pc,rate)
pp=zeros(1,4);

d=pc(3);
half_w=pc(4)/2;
half_h=half_w*rate;

pp(1)=(pc(1)-half_w)/d*camera.fx+camera.cx;
pp(2)=(pc(1)+half_w)/d*camera.fx+camera.cx;
pp(3)=(pc(2)-half_h)/d*camera.fy+camera.cy;
pp(4)=(pc(2)+half_h)/d*camera.fy+camera.cy;

end