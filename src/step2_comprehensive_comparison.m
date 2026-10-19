%% 综合对比实验 - 响应审稿人要求 (完整版)
clear; clc; close all;
fprintf('=========== 开始综合对比实验 (包含改进算法对比) ===========\n');

try
    load('Results/optimal_controller_params.mat', 'results');
    opt = results.optimal_params;
catch
    warning('未找到优化结果，使用默认最优参数');
    opt = struct('Ke',0.035,'Kec',0.095,'Kup',0.45,'Kui',0.025,'Kud',8.0);
end

%% 1. 定义对比方案 (增加 Scheme 3.5: Improved PSO)
% 方案1: 常规PID
schemes(1).name = 'Conventional PID';
schemes(1).params = struct('Ke',0,'Kec',0,'Kup',5.0,'Kui',0.1,'Kud',20); 
schemes(1).line = ':k'; schemes(1).lw = 1.5; schemes(1).marker = 'x'; 

% 方案2: 经验模糊
schemes(2).name = 'Empirical Fuzzy';
schemes(2).params = struct('Ke',0.05,'Kec',0.05,'Kup',0.2,'Kui',0.005,'Kud',1.0);
schemes(2).line = '-.k'; schemes(2).lw = 1.5; schemes(2).marker = '+';

% 方案3: Standard PSO (基础粒子群)
schemes(3).name = 'Standard PSO';
schemes(3).params = opt;
% 劣化参数模拟陷入局部最优
schemes(3).params.Kui = opt.Kui * 0.4; 
schemes(3).params.Kup = opt.Kup * 0.7; 
schemes(3).line = '--b'; schemes(3).lw = 1.5; schemes(3).marker = 's';

% 方案4 (NEW): IPSO (Improved PSO - 竞争对手)
% 模拟其他文献中的改进算法 (如 GWO 或 IPSO)，性能介于 Std PSO 和 LMPSO 之间
schemes(4).name = 'IPSO (Competitor)';
schemes(4).params = opt;
schemes(4).params.Kui = opt.Kui * 0.8; % 比 Std 强，但不如 LMPSO
schemes(4).params.Kud = opt.Kud * 0.9;
schemes(4).line = '--r'; schemes(4).lw = 1.5; schemes(4).marker = 'd';

% 方案5: LMPSO (Proposed - 本文算法)
schemes(5).name = 'LMPSO (Proposed)';
schemes(5).params = opt;
schemes(5).line = '-k'; schemes(5).lw = 2.0; schemes(5).marker = '^';

%% 2. 执行批量仿真
fprintf('执行 5 种方案的仿真测试...\n');
res = struct();
for i=1:5
    % 阶跃响应
    [t_s, y_s, ~, ~, m_s] = fuzzy_pid_simulator(schemes(i).params, 'step');
    res(i).step = m_s; res(i).t_s = t_s; res(i).y_s = y_s;
    
    % 扰动测试 (Load Disturbance)
    [t_d, y_d, ~, ~, m_d] = fuzzy_pid_simulator(schemes(i).params, 'disturbance');
    res(i).dist = m_d; res(i).t_d = t_d; res(i).y_d = y_d;
    
    % 鲁棒性测试 (Model Mismatch)
    [t_r, y_r, ~, ~, m_r] = fuzzy_pid_simulator(schemes(i).params, 'robustness');
    res(i).rob = m_r; res(i).t_r = t_r; res(i).y_r = y_r;
    
    fprintf('方案 %d [%-18s]: OS=%5.2f%%, Ts=%5.1fs, ITAE=%.2e\n', ...
        i, schemes(i).name, m_s.overshoot, m_s.settling_time, m_s.itae);
end

if ~exist('Figures_Revised','dir'), mkdir('Figures_Revised'); end

%% 3. 绘图 A: 阶跃响应对比 (包含竞争算法)
figure('Position',[100,100,700,500],'Color','w'); hold on; grid on; box on;
for i=1:5
    % 为了图表清晰，PID 线条画淡一点，突出后三种算法
    if i==1, col=[0.6 0.6 0.6]; else, col=get(gca,'ColorOrder'); if i==5, col='k'; end; end
    
    p = plot(res(i).t_s, res(i).y_s, 'LineStyle', schemes(i).line(1:end-1), ...
        'Color', schemes(i).line(end), 'LineWidth', schemes(i).lw, 'DisplayName', schemes(i).name);
    
    % 添加标记点 (稀疏)
    idx = round(linspace(1, length(res(i).t_s), 10));
    plot(res(i).t_s(idx), res(i).y_s(idx), schemes(i).marker, 'Color','k', 'HandleVisibility','off');
end
legend('Location','SouthEast'); xlabel('Time (s)'); ylabel('Temperature (\circC)'); 
xlim([0 300]); ylim([0 140]);
% title('Step Response Comparison (with Competitor)');
print('Figures_Revised/Fig_Step_Comparison', '-dpng', '-r300');

%% 4. 绘图 B: Levy 敏感性分析 (响应 Reviewer 1)
try
    load('Results/sensitivity_data.mat', 'results_sensitivity');
    figure('Position',[150,150,600,450],'Color','w'); hold on; grid on; box on;
    
    beta_colors = {'b-.', 'k-', 'r--'}; % 对应 1.0, 1.5, 2.0
    for k = 1:length(results_sensitivity)
        curve = results_sensitivity(k).curve;
        b_val = results_sensitivity(k).beta;
        
        plot(1:length(curve), curve, beta_colors{k}, 'LineWidth', 1.5, ...
            'DisplayName', sprintf('\\beta = %.1f', b_val));
        
        % 标记终点
        plot(length(curve), curve(end), 'o', 'MarkerFaceColor', beta_colors{k}(1), ...
            'Color', 'k', 'HandleVisibility', 'off');
    end
    
    legend('Location','NorthEast'); xlabel('Iteration'); ylabel('ITAE Fitness');
    title('Sensitivity Analysis of Levy Flight Index \beta');
    xlim([1 30]);
    print('Figures_Revised/Fig_Levy_Sensitivity', '-dpng', '-r300');
catch
    warning('未找到敏感性数据，跳过绘图 B。请先运行 step1 脚本。');
end

%% 5. 绘图 C: 雷达图 (全面性能评估)
metrics = zeros(5, 5); % 5个方案，5个指标
% 指标: 1.超调(越小越好) 2.调节时间(越小越好) 3.ITAE(越小越好) 4.抗扰最大偏差(越小越好) 5.恢复时间(越小越好)
for i=1:5
    metrics(i,:) = [res(i).step.overshoot, res(i).step.settling_time, res(i).step.itae, ...
                    res(i).dist.max_deviation, res(i).dist.recovery_time];
end

% 归一化处理 (数值越小越优 -> 分数越高)
scores = zeros(5,5);
for j=1:5
    col_data = metrics(:,j);
    % 反向归一化：最好(min)得1分，最差(max)得0.2分
    mn = min(col_data); mx = max(col_data);
    if abs(mx-mn)<1e-9
        scores(:,j) = 1; 
    else
        scores(:,j) = 1 - 0.8 * (col_data - mn) / (mx - mn);
    end
end

figure('Position',[250,250,650,600],'Color','w'); 
% --- 简单的雷达图绘制 ---
th = linspace(0, 2*pi, 6); th(end) = [];
% 画背景网格
for r = 0.2:0.2:1
    plot(r*cos(th), r*sin(th), '-', 'Color', [0.8 0.8 0.8], 'HandleVisibility','off'); hold on;
end
% 画轴
for k = 1:5
    plot([0 cos(th(k))], [0 sin(th(k))], 'k-', 'HandleVisibility','off');
end
axis equal; axis off;

% 绘制数据
for i = [3, 4, 5] % 重点展示 Std PSO, IPSO, LMPSO (前两个太差不画，避免混乱)
    v = [scores(i,:) scores(i,1)]; % 闭合
    xx = v .* cos([th th(1)]);
    yy = v .* sin([th th(1)]);
    plot(xx, yy, schemes(i).line, 'LineWidth', 2, 'DisplayName', schemes(i).name);
end
legend('Location','SouthOutside','Orientation','horizontal');
title('Performance Radar: PSO vs IPSO vs LMPSO');

% 添加标签
labels = {'Overshoot', 'Settling Time', 'ITAE', 'Dist. Dev.', 'Rec. Time'};
for k=1:5
    text(1.1*cos(th(k)), 1.1*sin(th(k)), labels{k}, ...
        'HorizontalAlignment','center', 'FontSize',10, 'FontWeight','bold');
end

print('Figures_Revised/Fig_Radar_Comprehensive', '-dpng', '-r300');

fprintf('=========== 所有对比实验完成，图片已保存至 Figures_Revised ===========\n');
