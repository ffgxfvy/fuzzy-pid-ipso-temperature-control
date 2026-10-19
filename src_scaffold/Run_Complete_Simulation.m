% 温度控制仿真 - 完整运行脚本
% 一键运行整个仿真流程

clear; clc; close all;

fprintf('========================================\n');
fprintf('     温度控制仿真 - 完整运行流程      \n');
fprintf('========================================\n\n');

% 1. 被控对象建模
fprintf('步骤1: 被控对象建模...\n');
run Scripts/plant_model.m

% 2. 模糊控制器设计
fprintf('步骤2: 模糊控制器设计...\n');
run Scripts/create_fuzzy_controller.m

% 3. LMPSO优化
fprintf('步骤3: LMPSO参数优化...\n');
fprintf('注意: 这一步可能需要较长时间 (3-5分钟)\n');
run Scripts/lmpso_optimization.m

% 4. 对比实验
fprintf('步骤4: 运行对比实验...\n');
run Scripts/run_comparison_experiments.m

% 完成
fprintf('========================================\n');
fprintf('     所有仿真步骤已完成！      \n');
fprintf('========================================\n');
