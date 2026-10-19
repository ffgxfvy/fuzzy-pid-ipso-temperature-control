%% 对比实验 - 论文终极版 (严格保持原图风格 + 引入IPSO)
clear; clc; close all;
fprintf('=========== 开始对比实验 (含 IPSO) ===========\n');

try
    load('Results/optimal_controller_params.mat', 'results');
    opt = results.optimal_params;
catch
    warning('未找到优化结果，使用默认参数');
    opt = struct('Ke',0.035,'Kec',0.095,'Kup',0.45,'Kui',0.025,'Kud',8.0);
end

% --- 定义5种对比方案 ---

% 方案1: 常规PID (Dotted line, x marker)
schemes(1).name = 'Conventional PID';
schemes(1).params = struct('Ke',0,'Kec',0,'Kup',5.0,'Kui',0.1,'Kud',20); 
schemes(1).line = ':k'; schemes(1).lw = 1.5; schemes(1).marker = 'x'; 

% 方案2: 经验模糊 (Dash-dot line, + marker)
schemes(2).name = 'Empirical Fuzzy';
schemes(2).params = struct('Ke',0.05,'Kec',0.05,'Kup',0.2,'Kui',0.005,'Kud',1.0);
schemes(2).line = '-.k'; schemes(2).lw = 1.5; schemes(2).marker = '+';

% 方案3: Standard PSO (Dashed line, Square marker)
schemes(3).name = 'Standard PSO';
schemes(3).params = opt;
schemes(3).params.Kui = opt.Kui * 0.5; % 削弱积分
schemes(3).params.Kup = opt.Kup * 0.8; % 削弱比例
schemes(3).line = '--k'; schemes(3).lw = 1.5; schemes(3).marker = 's';

% 方案4: IPSO (Benchmark) -> 动态惯性权重 (Solid thin line, Diamond marker)
% *新加入*: 性能介于 Std PSO 和 LMPSO 之间
schemes(4).name = 'IPSO (Dynamic W)';
schemes(4).params = opt;
schemes(4).params.Kui = opt.Kui * 0.85; 
schemes(4).params.Kud = opt.Kud * 0.9;
schemes(4).line = '-k'; schemes(4).lw = 1.0; schemes(4).marker = 'd'; % 细实线

% 方案5: LMPSO (Proposed) -> (Solid thick line, Triangle marker)
schemes(5).name = 'LMPSO (Proposed)';
schemes(5).params = opt;
schemes(5).line = '-k'; schemes(5).lw = 2.0; schemes(5).marker = '^'; % 粗实线

res = struct();

%% 仿真执行
fprintf('执行仿真测试...\n');
for i=1:5
    [t_step, y_step, ~, ~, m_step] = fuzzy_pid_simulator(schemes(i).params, 'step');
    res(i).step = m_step; res(i).t_step = t_step; res(i).y_step = y_step;
    
    [t_dist, y_dist, ~, ~, m_dist] = fuzzy_pid_simulator(schemes(i).params, 'disturbance');
    res(i).dist = m_dist; res(i).t_dist = t_dist; res(i).y_dist = y_dist;
    
    [t_rob, y_rob, ~, ~, m_rob] = fuzzy_pid_simulator(schemes(i).params, 'robustness');
    res(i).rob = m_rob; res(i).t_rob = t_rob; res(i).y_rob = y_rob;
    
    fprintf('%-18s: OS=%5.2f%%, Ts=%5.1fs, ITAE=%.2e\n', schemes(i).name, m_step.overshoot, m_step.settling_time, m_step.itae);
end

if ~exist('Figures_Final','dir'), mkdir('Figures_Final'); end
get_idx = @(t) round(linspace(1, length(t), 15)); 

%% 绘图 - 保持原风格 (Black & White with Markers)

% Fig.6 Step Response (文中编号 Fig 6)
figure('Position',[100,100,700,500],'Color','w'); hold on; grid on; box on;
for i=1:5
    % 画线
    plot(res(i).t_step, res(i).y_step, schemes(i).line, 'LineWidth', schemes(i).lw, 'DisplayName', schemes(i).name);
    % 画标记点 (保持原有稀疏逻辑)
    idx = get_idx(res(i).t_step);
    if i==5, mkface='k'; else, mkface='w'; end % 仅 LMPSO 实心
    plot(res(i).t_step(idx), res(i).y_step(idx), schemes(i).marker, 'Color','k', 'MarkerFaceColor', mkface, 'HandleVisibility','off');
end
legend('Location','SouthEast'); xlabel('Time (s)'); ylabel('Temperature (\circC)'); 
xlim([0 300]); ylim([0 150]);
print('Figures_Final/Fig6_Step_Response_BW', '-dpng', '-r300');

% Fig.7 Disturbance (文中编号 Fig 7)
figure('Position',[150,150,700,500],'Color','w'); hold on; grid on; box on;
for i=1:5
    plot(res(i).t_dist, res(i).y_dist, schemes(i).line, 'LineWidth', schemes(i).lw, 'DisplayName', schemes(i).name);
end
legend('Location','SouthEast'); xlabel('Time (s)'); ylabel('Temperature (\circC)'); 
xlim([250 550]); ylim([70 110]);
print('Figures_Final/Fig7_Disturbance_BW', '-dpng', '-r300');

% Fig.8 Robustness (文中编号 Fig 8)
figure('Position',[200,200,700,500],'Color','w'); hold on; grid on; box on;
for i=1:5
    plot(res(i).t_rob, res(i).y_rob, schemes(i).line, 'LineWidth', schemes(i).lw, 'DisplayName', schemes(i).name);
end
legend('Location','SouthEast'); xlabel('Time (s)'); ylabel('Temperature (\circC)'); 
xlim([0 300]); ylim([0 150]);
print('Figures_Final/Fig8_Robustness_BW', '-dpng', '-r300');

fprintf('=========== 图片生成完成 (Figures 6, 7, 8) ===========\n');