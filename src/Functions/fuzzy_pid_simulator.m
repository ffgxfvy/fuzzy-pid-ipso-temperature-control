%% 模糊PID仿真器 - 工业级稳定版
function [t, y, e, u, metrics] = fuzzy_pid_simulator(params, scenario, custom_plant)
    % 1. 加载参数
    if nargin < 3
        try
            d = load('Data/plant_parameters.mat'); plant_params = d.plant_params;
        catch
            plant_params.nominal = struct('K',1.5,'tau',120,'theta',30);
            plant_params.perturbed_combined = struct('K',1.35,'tau',150,'theta',30);
        end
    else
        plant_params = custom_plant;
    end
    
    Ts = 0.5;
    
    % 2. 场景定义
    switch scenario
        case 'step'
            t = 0:Ts:600; 
            setpoint = 100 * ones(size(t));
            dist_val = 0; dist_time = 9999;
            p = plant_params.nominal;
            
        case 'disturbance'
            t = 0:Ts:800;
            setpoint = 100 * ones(size(t));
            dist_val = -20; 
            dist_time = 300;
            p = plant_params.nominal;
            
        case 'robustness'
            t = 0:Ts:600;
            setpoint = 100 * ones(size(t));
            dist_val = 0; dist_time = 9999;
            if isfield(plant_params, 'perturbed_combined')
                p = plant_params.perturbed_combined;
            else
                p = struct('K',1.35,'tau',150,'theta',30);
            end
    end
    
    K_sys = p.K; tau_sys = p.tau; theta_sys = p.theta;
    
    % 3. 基准PID参数 (安全区：慢但稳)
    Kp0 = 3.0;  
    Ki0 = 0.03; % 降低积分，杜绝600s震荡
    Kd0 = 25.0; 
    
    % 加载控制器
    persistent fis;
    if isempty(fis)
        try fis = readfis('FIS_Files/fuzzy_pid_controller.fis');
        catch, error('请先运行 create_fuzzy_controller.m'); end
    end
    
    % 初始化
    N = length(t);
    y = zeros(1,N); e = zeros(1,N); u = zeros(1,N);
    integral = 0; e_last = 0;
    
    delay_steps = max(1, round(theta_sys/Ts));
    u_buffer = zeros(1, N+delay_steps+100);
    
    % 4. 仿真循环
    for k = 2:N
        e(k) = setpoint(k) - y(k-1);
        ec = (k>2) * (e(k)-e(k-1))/Ts;
        
        % 纯PID检测
        if params.Ke == 0 && params.Kec == 0
            % 允许外部强制指定PID参数
            if params.Kup > 0, Kp=params.Kup; Ki=params.Kui; Kd=params.Kud;
            else, Kp=Kp0; Ki=Ki0; Kd=Kd0; end
        else
            input = [max(min(e(k)*params.Ke, 100), -100), max(min(ec*params.Kec, 10), -10)];
            f_out = evalfis(fis, input);
            
            % 【关键】给模糊控制器极大的权限 (6倍放大)
            % 这意味着算法可以在动态过程中将 Ki 瞬间提升到 0.03 + 0.025*6 = 0.18
            % 从而实现极速响应，而在稳态时回落到 0.03 保持稳定
            scale = 6.0; 
            Kp = Kp0 + params.Kup * f_out(1) * scale;
            Ki = Ki0 + params.Kui * f_out(2) * scale;
            Kd = Kd0 + params.Kud * f_out(3) * 3.0;
        end
        
        Kp = max(0.1, Kp); Ki = max(1e-5, Ki); Kd = max(0.1, Kd);
        
        % 积分抗饱和
        if abs(e(k)) < 60 
            integral = integral + e(k)*Ts;
        end
        integral = max(min(integral, 20000), -20000); 
        
        derivative = (e(k)-e_last)/Ts;
        
        u_val = Kp*e(k) + Ki*integral + Kd*derivative;
        u(k) = max(min(u_val, 150), 0);
        
        u_act = u(k) + (t(k)>=dist_time)*dist_val;
        
        u_buffer(k) = u_act;
        if k > delay_steps
            u_delayed = u_buffer(k - delay_steps);
        else
            u_delayed = 0;
        end
        
        y(k) = y(k-1) + (Ts/tau_sys)*(K_sys*u_delayed - y(k-1));
        e_last = e(k);
    end
    
    % 指标计算
    metrics = calc_met(t, y, e, scenario);
end

function m = calc_met(t, y, e, type)
    m.overshoot = 0;
    m.settling_time = t(end);
    m.itae = sum(t.*abs(e))*(t(2)-t(1));
    m.max_deviation = 0; m.recovery_time = 0;
    
    if strcmp(type,'step') || strcmp(type,'robustness')
        if max(y)>100, m.overshoot = (max(y)-100); end 
        
        idx = find(abs(y-100)>2, 1, 'last');
        if isempty(idx)
            m.settling_time = 0;
        elseif idx < length(t)
            m.settling_time = t(idx+1);
        else
            m.settling_time = t(end);
        end
        
    elseif strcmp(type,'disturbance')
        idx = find(t>=300, 1);
        y_cut = y(idx:end);
        m.max_deviation = 100 - min(y_cut);
        
        idx_bad = find(y_cut < 98, 1, 'last');
        if ~isempty(idx_bad)
            global_idx = idx + idx_bad - 1;
            if global_idx <= length(t)
                m.recovery_time = t(global_idx) - 300;
            end
        end
    end
end