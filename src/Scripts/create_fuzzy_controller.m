%% 模糊PID控制器设计 - 论文支撑版
% 文件名：create_fuzzy_controller.m
% 对应论文：3.2节 模糊PID控制器结构

clear; clc;
fprintf('=========== 模糊PID控制器设计 ===========\n');
if ~exist('FIS_Files', 'dir'), mkdir('FIS_Files'); end

%% 创建Mamdani型模糊推理系统
fis = mamfis('Name', 'fuzzy_pid_controller');

% 输入变量: Error (e) [-100, 100]
fis = addInput(fis, [-100 100], 'Name', 'e');
fis = addMF(fis, 'e', 'trimf', [-100 -100 -60], 'Name', 'NB');
fis = addMF(fis, 'e', 'trimf', [-100 -60 -20], 'Name', 'NM');
fis = addMF(fis, 'e', 'trimf', [-60 -20 0], 'Name', 'NS');
fis = addMF(fis, 'e', 'trimf', [-20 0 20], 'Name', 'ZO');
fis = addMF(fis, 'e', 'trimf', [0 20 60], 'Name', 'PS');
fis = addMF(fis, 'e', 'trimf', [20 60 100], 'Name', 'PM');
fis = addMF(fis, 'e', 'trimf', [60 100 100], 'Name', 'PB');

% 输入变量: Error Rate (ec) [-10, 10]
fis = addInput(fis, [-10 10], 'Name', 'ec');
fis = addMF(fis, 'ec', 'trimf', [-10 -10 -6], 'Name', 'NB');
fis = addMF(fis, 'ec', 'trimf', [-10 -6 -2], 'Name', 'NM');
fis = addMF(fis, 'ec', 'trimf', [-6 -2 0], 'Name', 'NS');
fis = addMF(fis, 'ec', 'trimf', [-2 0 2], 'Name', 'ZO');
fis = addMF(fis, 'ec', 'trimf', [0 2 6], 'Name', 'PS');
fis = addMF(fis, 'ec', 'trimf', [2 6 10], 'Name', 'PM');
fis = addMF(fis, 'ec', 'trimf', [6 10 10], 'Name', 'PB');

% 输出变量: dKp, dKi, dKd [-1, 1]
% 注意：此处输出范围设为归一化[-1, 1]，实际增益由Kup/Kui/Kud决定
for output_name = {'dKp', 'dKi', 'dKd'}
    fis = addOutput(fis, [-1 1], 'Name', char(output_name));
    fis = addMF(fis, char(output_name), 'trimf', [-1 -1 -0.6], 'Name', 'NB');
    fis = addMF(fis, char(output_name), 'trimf', [-1 -0.6 -0.2], 'Name', 'NM');
    fis = addMF(fis, char(output_name), 'trimf', [-0.6 -0.2 0], 'Name', 'NS');
    fis = addMF(fis, char(output_name), 'trimf', [-0.2 0 0.2], 'Name', 'ZO');
    fis = addMF(fis, char(output_name), 'trimf', [0 0.2 0.6], 'Name', 'PS');
    fis = addMF(fis, char(output_name), 'trimf', [0.2 0.6 1], 'Name', 'PM');
    fis = addMF(fis, char(output_name), 'trimf', [0.6 1 1], 'Name', 'PB');
end

% 模糊规则 (49条经典规则)
% e, ec -> dKp, dKi, dKd
ruleList = [
    1 1 7 1 7 1 1; 1 2 7 1 6 1 1; 1 3 7 1 5 1 1; 1 4 7 2 4 1 1; 1 5 7 3 3 1 1; 1 6 7 4 2 1 1; 1 7 7 5 1 1 1;
    2 1 6 2 6 1 1; 2 2 6 2 5 1 1; 2 3 6 3 4 1 1; 2 4 6 4 3 1 1; 2 5 6 5 2 1 1; 2 6 6 6 1 1 1; 2 7 6 7 1 1 1;
    3 1 5 3 5 1 1; 3 2 5 3 4 1 1; 3 3 5 4 3 1 1; 3 4 5 5 2 1 1; 3 5 5 6 1 1 1; 3 6 5 7 1 1 1; 3 7 4 7 1 1 1;
    4 1 4 4 4 1 1; 4 2 4 5 3 1 1; 4 3 4 6 2 1 1; 4 4 4 7 1 1 1; 4 5 4 6 1 1 1; 4 6 4 5 1 1 1; 4 7 4 4 1 1 1;
    5 1 3 5 3 1 1; 5 2 3 5 2 1 1; 5 3 3 6 1 1 1; 5 4 3 7 1 1 1; 5 5 3 7 1 1 1; 5 6 2 7 1 1 1; 5 7 2 7 1 1 1;
    6 1 2 6 2 1 1; 6 2 2 6 1 1 1; 6 3 2 7 1 1 1; 6 4 2 7 1 1 1; 6 5 1 7 1 1 1; 6 6 1 7 1 1 1; 6 7 1 7 1 1 1;
    7 1 1 7 1 1 1; 7 2 1 7 1 1 1; 7 3 1 7 1 1 1; 7 4 1 7 1 1 1; 7 5 1 7 1 1 1; 7 6 1 7 1 1 1; 7 7 1 7 1 1 1;
];
fis = addRule(fis, ruleList);

writefis(fis, 'FIS_Files/fuzzy_pid_controller.fis');
fprintf('✓ 模糊控制器已保存: FIS_Files/fuzzy_pid_controller.fis\n');