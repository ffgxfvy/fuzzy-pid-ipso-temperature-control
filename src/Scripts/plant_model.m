%% 被控对象建模与 Fig.2 生成 - 黑白版
clear; clc; close all;
plant_params.nominal = struct('K',1.5, 'tau',120, 'theta',30, 'Ts',0.5);
plant_params.perturbed_tau = plant_params.nominal; plant_params.perturbed_tau.tau = 150;
plant_params.perturbed_gain = plant_params.nominal; plant_params.perturbed_gain.K = 1.35;
plant_params.perturbed_combined = struct('K',1.35, 'tau',150, 'theta',30);

if ~exist('Data', 'dir'), mkdir('Data'); end
save('Data/plant_parameters.mat', 'plant_params');

s = tf('s');
calc_tf = @(p) p.K * exp(-p.theta*s) / (p.tau*s + 1);
t = 0:1:600;
y1 = step(calc_tf(plant_params.nominal), t)*100;
y2 = step(calc_tf(plant_params.perturbed_tau), t)*100;
y3 = step(calc_tf(plant_params.perturbed_gain), t)*100;
y4 = step(calc_tf(plant_params.perturbed_combined), t)*100;

figure('Position', [100, 100, 800, 500], 'Color', 'w'); hold on; box on; grid on;
plot(t, y1, 'k-', 'LineWidth', 2.0, 'DisplayName', 'Nominal');
plot(t, y2, 'k--', 'LineWidth', 1.5, 'DisplayName', '\tau +25%');
plot(t, y3, 'k-.', 'LineWidth', 1.5, 'DisplayName', 'K -10%');
plot(t, y4, 'k:', 'LineWidth', 2.0, 'DisplayName', 'Combined');

xlabel('Time (s)'); ylabel('Temperature (\circC)');
title('Step Response of FOPDT Models');
legend('Location', 'SouthEast'); xlim([0 600]); ylim([0 160]);

if ~exist('Figures', 'dir'), mkdir('Figures'); end
print('Figures/Fig2_FOPDT_Step_Response_BW', '-dpng', '-r300');