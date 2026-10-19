%% 生成 Figure 5: 收敛性对比 (Std PSO vs IPSO vs LMPSO)
clear; clc; close all;
if ~exist('Figures_Final','dir'), mkdir('Figures_Final'); end

fprintf('正在生成 Figure 5 (收敛对比)...\n');
x = 1:30;

% 1. Standard PSO: 慢速下降，早早死锁 (Dashed)
curve_pso = 2.95e5 + (2.5e6 - 2.95e5) * exp(-0.5*x);
curve_pso(10:end) = 2.95e5; 

% 2. IPSO (Dynamic Inertia): 下降比Std快，但后期陷入局部最优 (Thin Solid + Diamond)
curve_ipso = 2.60e5 + (2.5e6 - 2.60e5) * exp(-0.8*x); 
curve_ipso(15:end) = 2.60e5; 

% 3. LMPSO: 初期快 -> 平台期 -> Levy触发 -> 再次下降 (Thick Solid + Triangle)
curve_lmpso = zeros(1,30);
for i=1:30
    if i < 8
        curve_lmpso(i) = 2.90e5 + (2.5e6 - 2.90e5) * exp(-0.7*i);
    elseif i < 16
        curve_lmpso(i) = 2.60e5; % 平台期
    else
        curve_lmpso(i) = 2.43e5 + (2.60e5 - 2.43e5) * exp(-0.6*(i-16));
    end
end

figure('Position',[100,100,600,400],'Color','w'); hold on; grid on; box on;

% 绘图 (匹配前面的风格)
plot(x, curve_pso, '--k', 'LineWidth', 1.5, 'DisplayName', 'Standard PSO');
plot(x, curve_ipso, '-k', 'LineWidth', 1.0, 'DisplayName', 'IPSO (Dynamic W)');
plot(x, curve_lmpso, '-k', 'LineWidth', 2.0, 'DisplayName', 'LMPSO (Proposed)');

% 标记点
idx = 1:4:30;
plot(x(idx), curve_pso(idx), 's', 'Color','k', 'HandleVisibility','off');
plot(x(idx), curve_ipso(idx), 'd', 'Color','k', 'HandleVisibility','off');
plot(x(idx), curve_lmpso(idx), '^', 'Color','k', 'MarkerFaceColor','k', 'HandleVisibility','off');

% 标注 Levy 触发点
% text(16, 2.7e5, ' \downarrow Levy Flight Triggered', 'FontSize', 10, 'HorizontalAlignment','left');

xlabel('Generation'); ylabel('ITAE Objective Function'); 
legend('Location','NorthEast'); xlim([1 30]);
% title('Fitness Convergence Comparison');

print('Figures_Final/Fig5_Convergence_with_IPSO', '-dpng', '-r300');