function [ s_inf ] = textSimpleTrans( s_Region,crx,cry, seta)
%textLinearTrans ����ļ�����״̬ת�ƺ���
%   ���㵥�������ڸ���������������Χ���ض���״̬��Ӱ��
%   ״̬��Ϊ���ػҶ�(0-1֮��)
%����:
%s_Region �ο�������״̬
%crx,cry������������
%seta �����������
%�����
%s_inf ���������״̬

s_Region(cry,crx)=0;
s_inf=s_Region*seta;
end