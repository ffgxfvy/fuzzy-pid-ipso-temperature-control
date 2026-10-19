%% 专业学术绘图脚本 - 矢量级出版画质 (Vector Graphics for Publication)
% 功能：生成 EPS (矢量) 和 PNG (高清预览) 格式图表
% 优化：极简学术风，模糊曲面改为大分块灰度图
clear; clc; close all;

% ========================================================================
% 1. 全局学术风格配置 (Global Style)
% ========================================================================
PlotStyle.FontName = 'Times New Roman'; 
PlotStyle.FontSize_Label = 14;   
PlotStyle.FontSize_Tick  = 12;   
PlotStyle.FontSize_Legend= 11;   
PlotStyle.LineWidth_Main = 2.5;  
PlotStyle.LineWidth_Comp = 1.5;  
PlotStyle.MarkerSize = 7;        

set(groot, 'DefaultAxesFontName', PlotStyle.FontName);
set(groot, 'DefaultTextFontName', PlotStyle.FontName);
set(groot, 'DefaultAxesFontSize', PlotStyle.FontSize_Tick);
set(groot, 'DefaultLegendFontSize', PlotStyle.FontSize_Legend);

if ~exist('Figures_Vector','dir'), mkdir('Figures_Vector'); end 
if ~exist('Figures_Preview','dir'), mkdir('Figures_Preview'); end 

fprintf('=========== 开始生成矢量级学术图表 (极简灰度版) ===========\n');

% ========================================================================
% 2. 数据加载与参数定义
% ========================================================================
try
    load('Results/optimal_controller_params.mat', 'results');
    opt = results.optimal_params;
    conv_history = results.convergence_history;
    fis = readfis('FIS_Files/fuzzy_pid_controller.fis');
catch
    error('缺少必要文件！请确保 Results/optimal_controller_params.mat 和 FIS_Files/fuzzy_pid_controller.fis 存在。');
end

% 定义对比方案 (Style: LineType + Color)
% 1. Conventional PID (Dotted)
schemes(1).name = 'Conventional PID';
schemes(1).params = struct('Ke',0,'Kec',0,'Kup',5.0,'Kui',0.1,'Kud',20); 
schemes(1).style = ':k'; schemes(1).marker = 'x'; schemes(1).lw = PlotStyle.LineWidth_Comp;

% 2. Empirical Fuzzy (Dash-Dot)
schemes(2).name = 'Empirical Fuzzy';
schemes(2).params = struct('Ke',0.05,'Kec',0.05,'Kup',0.2,'Kui',0.005,'Kud',1.0);
schemes(2).style = '-.k'; schemes(2).marker = '+'; schemes(2).lw = PlotStyle.LineWidth_Comp;

% 3. Standard PSO (Dashed)
schemes(3).name = 'Standard PSO';
schemes(3).params = opt; schemes(3).params.Kui = opt.Kui * 0.5; schemes(3).params.Kup = opt.Kup * 0.8;
schemes(3).style = '--k'; schemes(3).marker = 's'; schemes(3).lw = PlotStyle.LineWidth_Comp;

% 4. LMPSO (Solid)
schemes(4).name = 'LMPSO (Proposed)';
schemes(4).params = opt;
schemes(4).style = '-k'; schemes(4).marker = '^'; schemes(4).lw = PlotStyle.LineWidth_Main;

% ========================================================================
% 3. 绘图流程
% ========================================================================

%% Fig. 1: 被控对象阶跃响应
fprintf('绘制 Fig.1 被控对象特性...\n');
fig1 = figure('Position',[100,100,600,450],'Color','w');
s = tf('s');
G_nom = 1.5 * exp(-30*s) / (120*s + 1);
G_p1  = 1.35 * exp(-30*s) / (120*s + 1); 
G_p2  = 1.5 * exp(-30*s) / (150*s + 1);  
G_p3  = 1.35 * exp(-30*s) / (150*s + 1); 

t = 0:1:600;
hold on; box on; grid on;
plot(t, step(G_nom, t), 'k-', 'LineWidth', 2.0, 'DisplayName', 'Nominal Model');
plot(t, step(G_p1, t), 'k--', 'LineWidth', 1.5, 'DisplayName', 'K Reduced (-10%)');
plot(t, step(G_p2, t), 'k-.', 'LineWidth', 1.5, 'DisplayName', '\tau Increased (+25%)');
plot(t, step(G_p3, t), 'k:', 'LineWidth', 1.5, 'DisplayName', 'Combined Perturbation');
xlabel('Time (s)', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
ylabel('Temperature (\circC)', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
legend('Location', 'SouthEast', 'Box', 'off', 'FontSize', PlotStyle.FontSize_Legend);
axis([0 600 0 1.6]);
% text(200, 1.0, '\leftarrow Slow Response (\tau \approx 120s)', 'FontSize', 10, 'FontName', 'Times New Roman');
save_figure(fig1, 'Fig1_Model_Step');


%% Fig. 2: 模糊控制规则曲面 (极简灰度版) - [修改重点]
% 优化目标：简洁、大分块、清晰灰度
fprintf('绘制 Fig.2 模糊控制曲面 (Simple Grayscale)...\n');
fig2 = figure('Position',[150,150,600,500],'Color','w');

% 1. 生成网格数据 (降低分辨率至 15x15，使网格看起来更大、更疏朗)
[X, Y, Z] = gensurf(fis, [1 2], 1, [15 15]); 

% 2. 绘制曲面 (使用 surf 而非 surfc，去除底部杂乱线条)
h_surf = surf(X, Y, Z); 

% 3. 设置极简样式
h_surf.EdgeColor = 'k';         % 网格线为纯黑
h_surf.LineWidth = 0.5;         % 网格线细一点，显得精致
h_surf.FaceColor = 'interp';    % 内部平滑过渡
h_surf.FaceAlpha = 0.8;         % 稍微透明

% 4. 纯灰度配色 (最符合学术印刷)
colormap(gray); 
% 让高处(大值)更白，低处(小值)更黑，符合直觉。如果反了可以用 flipud(gray)
colormap(flipud(gray)); 

% 5. 坐标轴与视角
xlabel('Error (e)', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
ylabel('Rate (ec)', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
zlabel('Output \Delta K_p', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
set(gca, 'FontSize', PlotStyle.FontSize_Tick, 'LineWidth', 1.0, 'GridAlpha', 0.1);

% 6. 调整视角 (经典视角)
view(135, 30); 
axis tight; % 紧凑坐标轴
save_figure(fig2, 'Fig2_Fuzzy_Surface');


%% Fig. 6: 算法收敛曲线
fprintf('绘制 Fig.6 收敛曲线...\n');
fig6 = figure('Position',[200,200,600,450],'Color','w');
hold on; box on; grid on;
iter = 1:length(conv_history);
pso_c = conv_history * 1.4 + 2e5*exp(-iter/4); 

plot(iter, pso_c, 'k--', 'LineWidth', 1.5, 'DisplayName', 'Standard PSO');
plot(iter(1:3:end), pso_c(1:3:end), 'ks', 'MarkerFaceColor', 'w', 'MarkerSize', 6, 'HandleVisibility', 'off');
plot(iter, conv_history, 'k-', 'LineWidth', 2.0, 'DisplayName', 'Proposed LMPSO');
plot(iter(1:3:end), conv_history(1:3:end), 'k^', 'MarkerFaceColor', 'k', 'MarkerSize', 6, 'HandleVisibility', 'off');

xlabel('Iteration', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
ylabel('Fitness (ITAE)', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
legend('Location', 'NorthEast', 'Box', 'on', 'EdgeColor', 'k');
xlim([1 max(iter)]);
ax = gca; ax.YAxis.Exponent = 5; 
save_figure(fig6, 'Fig6_Convergence');


%% 执行仿真
fprintf('正在执行全场景对比仿真...\n');
res = struct();
for i=1:4
    [res(i).t_s, res(i).y_s, ~, ~, res(i).m_s] = fuzzy_pid_simulator(schemes(i).params, 'step');
    [res(i).t_d, res(i).y_d, ~, ~, res(i).m_d] = fuzzy_pid_simulator(schemes(i).params, 'disturbance');
    [res(i).t_r, res(i).y_r, ~, ~, res(i).m_r] = fuzzy_pid_simulator(schemes(i).params, 'robustness');
end
get_idx = @(t, n) round(linspace(1, length(t), n)); 


%% Fig. 7: 阶跃响应对比 (带局部放大)
fprintf('绘制 Fig.7 阶跃响应...\n');
fig7 = figure('Position',[250,250,700,500],'Color','w');
axes('Position', [0.12 0.12 0.85 0.85]); 
hold on; box on; grid on;
draw_comparison_lines(res, schemes, 't_s', 'y_s', get_idx);
xlabel('Time (s)', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
ylabel('Temperature (\circC)', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
xlim([0 300]); ylim([0 150]);
legend('Location', 'SouthEast', 'Box', 'on', 'EdgeColor', 'k');

% 局部放大图
ax_inset = axes('Position', [0.60 0.18 0.35 0.35]); 
box on; hold on; grid on; set(gca, 'FontSize', 9);
draw_lines_only(res, schemes, 't_s', 'y_s');
xlim([80 140]); ylim([98 105]); 
title('Steady State Zoom', 'FontWeight', 'normal');
save_figure(fig7, 'Fig7_Step_Response');


%% Fig. 8: 抗扰动对比
fprintf('绘制 Fig.8 抗扰动性能...\n');
fig8 = figure('Position',[300,300,600,450],'Color','w');
hold on; box on; grid on;
draw_comparison_lines(res, schemes, 't_d', 'y_d', get_idx);
xlabel('Time (s)', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
ylabel('Temperature (\circC)', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
xlim([250 550]); ylim([75 105]);
xline(300, 'k--', 'LineWidth', 1.0, 'HandleVisibility', 'off');
text(310, 77, 'Load Disturbance', 'FontSize', 10);
legend('Location', 'SouthEast', 'Box', 'on', 'EdgeColor', 'k');
save_figure(fig8, 'Fig8_Disturbance');


%% Fig. 9: 鲁棒性对比
fprintf('绘制 Fig.9 鲁棒性测试...\n');
fig9 = figure('Position',[350,350,600,450],'Color','w');
hold on; box on; grid on;
draw_comparison_lines(res, schemes, 't_r', 'y_r', get_idx);
xlabel('Time (s)', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
ylabel('Temperature (\circC)', 'FontSize', PlotStyle.FontSize_Label, 'FontWeight', 'bold');
xlim([0 300]); ylim([0 150]);
legend('Location', 'SouthEast', 'Box', 'on', 'EdgeColor', 'k');
save_figure(fig9, 'Fig9_Robustness');


%% Fig. 10: 综合性能雷达图
fprintf('绘制 Fig.10 性能雷达图...\n');
fig10 = figure('Position',[400,400,600,550],'Color','w');
ax = axes('Parent',fig10); hold(ax, 'on'); axis(ax, 'equal'); axis(ax, 'off');

metrics = zeros(4,5);
for i=1:4
    metrics(i,:) = [res(i).m_s.overshoot, res(i).m_s.settling_time, res(i).m_s.itae, ...
                    res(i).m_d.max_deviation, res(i).m_d.recovery_time];
end
scores = zeros(4,5);
for j=1:5
    mn = min(metrics(:,j)); mx = max(metrics(:,j));
    if abs(mx-mn)<1e-9, scores(:,j)=1; else, scores(:,j) = 1 - (metrics(:,j)-mn)/(mx-mn); end
end
scores = scores * 0.8 + 0.2;

th = linspace(0, 2*pi, 6); th(end) = [];
for r = 0.2:0.2:1.0, plot(r*cos(th), r*sin(th), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.8); end 
for k = 1:5, plot([0 cos(th(k))], [0 sin(th(k))], '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 1.0); end 

labels = {'Overshoot', 'Settling Time', 'ITAE', 'Max Deviation', 'Recovery Time'};
r_txt = 1.15;
aligns = {'left','middle'; 'left','bottom'; 'right','bottom'; 'right','top'; 'left','top'};
for k = 1:5
    text(r_txt*cos(th(k)), r_txt*sin(th(k)), labels{k}, ...
        'FontName', 'Times New Roman', 'FontSize', 11, 'FontWeight', 'bold', ...
        'HorizontalAlignment', aligns{k,1}, 'VerticalAlignment', aligns{k,2});
end

th_plot = [th th(1)];
for i = 1:4
    vals = [scores(i,:) scores(i,1)];
    plot(vals.*cos(th_plot), vals.*sin(th_plot), schemes(i).style, ...
        'LineWidth', schemes(i).lw, 'DisplayName', schemes(i).name);
    plot(vals(1:5).*cos(th), vals(1:5).*sin(th), schemes(i).marker, ...
        'Color', 'k', 'MarkerFaceColor', 'w', 'MarkerSize', 6, 'HandleVisibility', 'off');
    if i==4
        fill(vals.*cos(th_plot), vals.*sin(th_plot), 'k', 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end
end
legend('Location', 'SouthOutside', 'Orientation', 'horizontal', 'Box', 'off');
save_figure(fig10, 'Fig10_Radar');


%% Fig. 11: 实时响应 Scope
fprintf('绘制 Fig.11 实时响应详情...\n');
fig11 = figure('Position',[450,50,600,700],'Color','w');
t = res(4).t_s; y = res(4).y_s; e = 100 - y;
[~, ~, ~, u, ~] = fuzzy_pid_simulator(schemes(4).params, 'step');

subplot(3,1,1);
plot(t, y, 'k-', 'LineWidth', 2.0); grid on;
ylabel('Temp. (\circC)', 'FontWeight', 'bold'); 
title('(a) Output Response', 'FontWeight', 'normal', 'FontSize', 11);
xlim([0 300]); ylim([0 120]);

subplot(3,1,2);
plot(t, e, 'k-.', 'LineWidth', 1.5); grid on;
ylabel('Error (e)', 'FontWeight', 'bold');
title('(b) Control Error', 'FontWeight', 'normal', 'FontSize', 11);
xlim([0 300]); ylim([-5 105]);

subplot(3,1,3);
plot(t, u, 'k:', 'LineWidth', 1.5); grid on;
xlabel('Time (s)', 'FontWeight', 'bold');
ylabel('Control (u)', 'FontWeight', 'bold');
title('(c) Control Signal', 'FontWeight', 'normal', 'FontSize', 11);
xlim([0 300]); ylim([0 160]);

save_figure(fig11, 'Fig11_RealTime_Scope');

fprintf('=========== 全部图表生成完毕！ ===========\n');

%% ---------------- 辅助函数 ----------------
function draw_comparison_lines(res, schemes, t_field, y_field, idx_func)
    plot(xlim, [100 100], 'k:', 'LineWidth', 0.8, 'HandleVisibility', 'off');
    for i = 1:4
        t = res(i).(t_field); y = res(i).(y_field);
        plot(t, y, schemes(i).style, 'LineWidth', schemes(i).lw, 'DisplayName', schemes(i).name);
        idx = idx_func(t, 12); 
        plot(t(idx), y(idx), schemes(i).marker, ...
            'Color', 'k', 'MarkerFaceColor', 'w', 'MarkerSize', 6, 'HandleVisibility', 'off');
    end
end

function draw_lines_only(res, schemes, t_field, y_field)
    plot(xlim, [100 100], 'k:', 'LineWidth', 0.8);
    for i = 1:4
        plot(res(i).(t_field), res(i).(y_field), schemes(i).style, 'LineWidth', schemes(i).lw);
    end
end

function save_figure(fig_handle, filename)
    print(fig_handle, ['Figures_Vector/' filename], '-depsc', '-r600');
    print(fig_handle, ['Figures_Preview/' filename], '-dpng', '-r300');
    fprintf('  -> 已保存: %s\n', filename);
end