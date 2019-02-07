function createfigure(X1, YMatrix1)
%CREATEFIGURE(X1, YMATRIX1)
%  X1:  x ���ݵ�ʸ��
%  YMATRIX1:  y ���ݵľ���

%  �� MATLAB �� 01-Nov-2018 15:49:11 �Զ�����

% ���� figure
figure1 = figure;

% ���� axes
axes1 = axes('Parent',figure1);
box(axes1,'on');
hold(axes1,'all');

% ʹ�� plot �ľ������봴������
plot1 = plot(X1,YMatrix1,'Parent',axes1);
set(plot1(1),'Color',[1 0.5 0.1],'DisplayName','OAO-DPT');
set(plot1(2),'Color',[0.1 0.6 1],'DisplayName','MAP-CT');

% ���� xlabel
xlabel('k');

% ���� ylabel
ylabel('ms');

% ���� legend
legend1 = legend(axes1,'show');
set(legend1,...
    'Position',[0.184447605500234 0.745529507306775 0.381578947368421 0.156133828996283]);

