function [Uc_average, Us_average, Ic_average, Is_average, Valid] = ...
    Average_Mean_Cycle(Uc, Us, Ic, Is, Freq, PNUM, EN, Ts, WAIT_CYCLES, AVG_CYCLES)
%#codegen
%
% Version: 1.3.0
% Date: 2026-11-03
% Status: Final user-designated version; retain prior versions for rollback.
%
% 阻抗扫频：基于Ts的完整周期累加平均
%
% 1. PNUM变化时自动切换扫频点
% 2. 内部使用 Freq*Ts 累计周期相位
% 3. 等待WAIT_CYCLES个完整周期
% 4. 对随后AVG_CYCLES个完整周期进行平均
% 5. 不使用大型采样缓存
% 6. 每个PNUM只产生一次Valid
% 7. Valid仅保持一个MATLAB Function执行周期
%
% 扫频点实际驻留周期：
% WAIT_CYCLES + AVG_CYCLES + 0.1
%
% 注意：
% 额外0.1周期由外部扫频计数器实现
% 不参与平均，也不延长Valid脉冲
%
% MATLAB Function必须每隔Ts执行一次
% 当前Ts = 8e-8 s

%% ===== 1. 输入信号标量化 =====

uc = Uc(1);
us = Us(1);
ic = Ic(1);
is = Is(1);

freq = Freq(1);
pnum = PNUM(1);
en = EN(1);
ts = Ts(1);

waitN = round(WAIT_CYCLES(1));
avgN = round(AVG_CYCLES(1));

if waitN < 0
    waitN = 0;
end

if avgN < 1
    avgN = 1;
end

%% ===== 2. 内部状态 =====

persistent initialized
persistent prevEN prevPNUM
persistent prevWaitN prevAvgN

persistent phaseFrac completedCycles

persistent cycleSum cycleCount
persistent totalSum totalCount
persistent avgCycleCount

persistent outData
persistent validSent measurementDone

%% ===== 3. 初始化 =====

if isempty(initialized)

    initialized = true;

    prevEN = false;
    prevPNUM = pnum;

    prevWaitN = waitN;
    prevAvgN = avgN;

    phaseFrac = 0;
    completedCycles = 0;

    cycleSum = zeros(1,4);
    cycleCount = 0;

    totalSum = zeros(1,4);
    totalCount = 0;

    avgCycleCount = 0;

    outData = zeros(1,4);

    validSent = false;
    measurementDone = false;

end

%% ===== 4. Valid默认拉低 =====

% 每次函数执行均默认Valid=0
% 只有平均完成的那一次执行才输出Valid=1

Valid = 0;

%% ===== 5. EN关闭时复位 =====

if en <= 0.5

    prevEN = false;
    prevPNUM = pnum;

    prevWaitN = waitN;
    prevAvgN = avgN;

    phaseFrac = 0;
    completedCycles = 0;

    cycleSum = zeros(1,4);
    cycleCount = 0;

    totalSum = zeros(1,4);
    totalCount = 0;

    avgCycleCount = 0;

    outData = zeros(1,4);

    validSent = false;
    measurementDone = false;

else

    %% ===== 6. 检测新扫频点 =====

    pnumChanged = abs(pnum-prevPNUM) > 0.5;

    parameterChanged = ...
        (waitN ~= prevWaitN) || ...
        (avgN ~= prevAvgN);

    newPoint = (~prevEN) || ...
               pnumChanged || ...
               parameterChanged;

    if newPoint

        % 新扫频点从零开始累计相位
        phaseFrac = 0;
        completedCycles = 0;

        % 清空当前周期数据
        cycleSum = zeros(1,4);
        cycleCount = 0;

        % 清空平均数据
        totalSum = zeros(1,4);
        totalCount = 0;

        avgCycleCount = 0;

        outData = zeros(1,4);

        % 重新允许单次触发
        validSent = false;
        measurementDone = false;

    end

    %% ===== 7. 内部相位累计 =====

    % 要求每次函数执行时 freq*ts < 1
    phaseStep = freq * ts;

    if phaseStep > 0 && phaseStep < 1 && ...
            ~measurementDone

        %% 当前采样点累加

        cycleSum(1) = cycleSum(1) + uc;
        cycleSum(2) = cycleSum(2) + us;
        cycleSum(3) = cycleSum(3) + ic;
        cycleSum(4) = cycleSum(4) + is;

        cycleCount = cycleCount + 1;

        %% 使用实际Ts累计相位

        phaseFrac = phaseFrac + phaseStep;

        %% ===== 8. 判断完整周期是否结束 =====

        if phaseFrac >= 1.0

            phaseFrac = phaseFrac - 1.0;

            completedCycles = completedCycles + 1;

            %% ===== 9. 跳过等待周期 =====

            if completedCycles > waitN && cycleCount > 0

                % 保存当前完整周期的采样数据
                totalSum = totalSum + cycleSum;

                totalCount = totalCount + cycleCount;

                avgCycleCount = avgCycleCount + 1;

                %% ===== 10. 完成指定周期平均 =====

                if avgCycleCount >= avgN && totalCount > 0

                    % 四路信号统一按照总采样点数求平均
                    outData = totalSum / totalCount;

                    %% ===== 11. Valid单次触发 =====

                    if ~validSent

                        Valid = 1;

                        validSent = true;

                        % 锁定测量完成状态
                        % 后续0.1周期内不再计算、不再触发

                        measurementDone = true;

                    end

                end

            end

            %% 开始统计下一个周期

            cycleSum = zeros(1,4);
            cycleCount = 0;

        end

    end

    %% ===== 12. 更新扫频状态 =====

    prevEN = true;
    prevPNUM = pnum;

    prevWaitN = waitN;
    prevAvgN = avgN;

end

%% ===== 13. 输出 =====

Uc_average = outData(1);
Us_average = outData(2);
Ic_average = outData(3);
Is_average = outData(4);

end
