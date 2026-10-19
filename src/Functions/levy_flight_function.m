%% Levy飞行函数实现

% 文件名：levy_flight_function.m
% 对应论文：3.3节 Levy飞行变异机制

function step = levy_flight_function(dim, beta, scale_factor)
    % 生成Levy分布的随机步长
    % 输入: dim - 维度, beta - Levy指数(默认1.5), scale_factor - 缩放因子
    % 输出: step - Levy飞行步长向量
    
    if nargin < 2
        beta = 1.5; % 论文中常用值
    end
    
    if nargin < 3
        scale_factor = 1.0;
    end
    
    % 计算Levy分布参数
    numerator = gamma(1 + beta) * sin(pi * beta / 2);
    denominator = gamma((1 + beta) / 2) * beta * 2^((beta - 1) / 2);
    sigma = (numerator / denominator)^(1 / beta);
    
    % 生成随机向量
    u = randn(1, dim) * sigma;
    v = randn(1, dim);
    
    % 计算Levy步长
    step = u ./ (abs(v).^(1 / beta));
    step = step * scale_factor;
    
    % 防止无效值
    if any(isinf(step)) || any(isnan(step))
        step = randn(1, dim) * 0.1; % 使用正态分布替代
    end
end