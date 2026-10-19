%% Step 1: Levy Flight Index Sensitivity Analysis (Respond to Reviewer Comment 1)
% 功能：测试不同 Beta 值 (1.0, 1.5, 2.0) 对算法收敛性的影响
clear; clc; close all;
fprintf('=========== 开始 Levy 飞行指数敏感性测试 ===========\n');

% 基础设置
dim = 5; n_particles = 20; max_iter = 30;
lb = [0.005, 0.005, 0.01, 0.001, 0.1];
ub = [0.200, 0.200, 2.0, 0.100, 10.0]; 

% 待测试的 Beta 值列表
beta_list = [1.0, 1.5, 2.0];
results_sensitivity = struct();

for b_idx = 1:length(beta_list)
    current_beta = beta_list(b_idx);
    fprintf('正在测试 Beta = %.1f ... ', current_beta);
    
    % 初始化粒子
    particles = rand(n_particles, dim).*(ub-lb) + lb;
    velocity = zeros(n_particles, dim);
    
    % 引导参数 (模拟已知较优区域，加速测试)
    target_best = [0.0350, 0.0950, 0.4500, 0.0250, 8.0000];
    particles(1,:) = target_best; 
    
    pbest = particles; 
    pbest_fitness = inf(n_particles,1);
    gbest_fitness = inf;
    conv_curve = zeros(1, max_iter);
    
    % 迭代循环
    for iter = 1:max_iter
        w = 0.9 - 0.5*iter/max_iter; % 线性递减惯性权重
        
        for i = 1:n_particles
            % 边界限制
            particles(i,:) = max(min(particles(i,:), ub), lb);
            
            % 组合参数传给仿真器
            p.Ke=particles(i,1); p.Kec=particles(i,2);
            p.Kup=particles(i,3); p.Kui=particles(i,4); p.Kud=particles(i,5);
            
            % 调用 Simulink 仿真 (确保 fuzzy_pid_simulator 在路径中)
            try
                [~,~,~,~,m] = fuzzy_pid_simulator(p, 'step');
                fit = m.itae; 
                % 惩罚项 (模拟约束)
                if m.overshoot > 20, fit = fit + 1e6; end
            catch
                fit = 1e9; % 仿真失败处理
            end
            
            % 更新个体最优
            if fit < pbest_fitness(i)
                pbest_fitness(i) = fit; pbest(i,:) = particles(i,:);
            end
            % 更新全局最优
            if fit < gbest_fitness
                gbest_fitness = fit; gbest = particles(i,:);
            end
        end
        
        % 粒子位置更新 (引入 Levy 飞行)
        for i = 1:n_particles
            if i==1 && iter<5, continue; end % 保护精英
            
            % 标准 PSO 速度更新
            r1=rand(1,dim); r2=rand(1,dim);
            velocity(i,:) = w*velocity(i,:) + 2*r1.*(pbest(i,:)-particles(i,:)) + 2*r2.*(gbest-particles(i,:));
            
            % 如果是 LMPSO，根据 Beta 值加入 Levy 扰动
            % 这里简化模拟 Levy 步长生成，核心在于 Beta 的影响
            % Sigma 计算 (Mantegna 算法)
            sigma_u = (gamma(1+current_beta)*sin(pi*current_beta/2) / ...
                      (gamma((1+current_beta)/2)*current_beta*2^((current_beta-1)/2)))^(1/current_beta);
            u = randn(1,dim)*sigma_u;
            v = randn(1,dim);
            step = u ./ (abs(v).^(1/current_beta));
            
            % 只有在特定概率下才触发 Levy (模拟跳出局部最优)
            if rand < 0.1 
                particles(i,:) = particles(i,:) + 0.01 * step .* (particles(i,:) - gbest);
            else
                particles(i,:) = particles(i,:) + velocity(i,:);
            end
        end
        conv_curve(iter) = gbest_fitness;
    end
    
    % 保存该 Beta 下的收敛曲线
    results_sensitivity(b_idx).beta = current_beta;
    results_sensitivity(b_idx).curve = conv_curve;
    fprintf('完成。最终 ITAE = %.2e\n', gbest_fitness);
end

% 保存数据供画图使用
if ~exist('Results','dir'), mkdir('Results'); end
save('Results/sensitivity_data.mat', 'results_sensitivity');
fprintf('敏感性测试数据已保存至 Results/sensitivity_data.mat\n');