function [Uc_average, Us_average, Ic_average, Is_average, Valid] = ...
    Average_Mean_Cycle(Uc, Us, Ic, Is, Freq, PNUM, EN, Phase, Ts, WAIT_CYCLES, AVG_CYCLES)
%#codegen
%
% Version: 1.1.0
% Date: 2026-11-03
%
% Impedance sweep: complete-cycle batch averaging.
%
% WAIT_CYCLES : number of complete cycles to wait after a new sweep point
% AVG_CYCLES  : number of complete cycles to accumulate for the average
%
% Phase is a continuously accumulated cycle count:
% Phase(k) = Phase(k-1) + Freq * Ts
%
% This version does not use a sample-history buffer.
% It accumulates samples within each cycle and then accumulates the
% requested number of complete cycles.

%% ===== 1. Scalarize inputs =====

uc = Uc(1);
us = Us(1);
ic = Ic(1);
is = Is(1);

freq = Freq(1);
pnum = PNUM(1);
en = EN(1);
phaseValue = Phase(1);
ts = Ts(1);

waitN = round(WAIT_CYCLES(1));
avgN = round(AVG_CYCLES(1));

if waitN < 0
    waitN = 0;
end

if avgN < 1
    avgN = 1;
end

%% ===== 2. Persistent states =====

persistent initialized
persistent prevEN prevPNUM
persistent prevWaitN prevAvgN

persistent phaseStart
persistent lastCycle

persistent cycleSum cycleCount
persistent totalSum totalCount
persistent avgCycleCount

persistent outData
persistent validSent

%% ===== 3. Initialization =====

if isempty(initialized)

    initialized = true;

    prevEN = false;
    prevPNUM = pnum;

    prevWaitN = waitN;
    prevAvgN = avgN;

    phaseStart = phaseValue;
    lastCycle = 0;

    cycleSum = zeros(1,4);
    cycleCount = 0;

    totalSum = zeros(1,4);
    totalCount = 0;

    avgCycleCount = 0;

    outData = zeros(1,4);

    validSent = false;

end

%% ===== 4. Valid defaults to zero =====

Valid = 0;

%% ===== 5. Reset when disabled =====

if en <= 0.5

    prevEN = false;
    prevPNUM = pnum;

    prevWaitN = waitN;
    prevAvgN = avgN;

    phaseStart = phaseValue;
    lastCycle = 0;

    cycleSum = zeros(1,4);
    cycleCount = 0;

    totalSum = zeros(1,4);
    totalCount = 0;

    avgCycleCount = 0;

    outData = zeros(1,4);

    validSent = false;

else

    %% ===== 6. Detect a new sweep point =====

    pnumChanged = abs(pnum-prevPNUM) > 0.5;

    parameterChanged = ...
        (waitN ~= prevWaitN) || ...
        (avgN ~= prevAvgN);

    newPoint = (~prevEN) || ...
               pnumChanged || ...
               parameterChanged;

    if newPoint

        phaseStart = phaseValue;
        lastCycle = 0;

        cycleSum = zeros(1,4);
        cycleCount = 0;

        totalSum = zeros(1,4);
        totalCount = 0;

        avgCycleCount = 0;

        outData = zeros(1,4);

        validSent = false;

    end

    %% ===== 7. Detect complete cycle boundaries =====

    if freq > 0 && ts > 0

        elapsedCycles = phaseValue - phaseStart;

        %% Phase-reset protection

        if elapsedCycles < -1e-9

            phaseStart = phaseValue;
            lastCycle = 0;

            cycleSum = zeros(1,4);
            cycleCount = 0;

            totalSum = zeros(1,4);
            totalCount = 0;

            avgCycleCount = 0;

            outData = zeros(1,4);

            validSent = false;

        else

            cycleNow = floor(elapsedCycles + 1e-10);

            %% ===== 8. Process the completed cycle =====

            if cycleNow > lastCycle

                % Ignore the first WAIT_CYCLES complete cycles.
                % Then accumulate AVG_CYCLES complete cycles.

                if lastCycle >= waitN && ...
                   cycleCount > 0 && ...
                   avgCycleCount < avgN

                    totalSum = totalSum + cycleSum;
                    totalCount = totalCount + cycleCount;

                    avgCycleCount = avgCycleCount + 1;

                    %% Complete the requested average

                    if avgCycleCount >= avgN && totalCount > 0

                        outData = totalSum / totalCount;

                        % One Valid pulse per sweep point
                        if ~validSent

                            Valid = 1;
                            validSent = true;

                        end

                    end

                end

                % Start collecting the next cycle
                lastCycle = cycleNow;

                cycleSum = zeros(1,4);
                cycleCount = 0;

            end

            %% ===== 9. Accumulate the current sample =====

            if avgCycleCount < avgN

                cycleSum(1) = cycleSum(1) + uc;
                cycleSum(2) = cycleSum(2) + us;
                cycleSum(3) = cycleSum(3) + ic;
                cycleSum(4) = cycleSum(4) + is;

                cycleCount = cycleCount + 1;

            end

        end

    end

    %% ===== 10. Update sweep states =====

    prevEN = true;
    prevPNUM = pnum;

    prevWaitN = waitN;
    prevAvgN = avgN;

end

%% ===== 11. Outputs =====

Uc_average = outData(1);
Us_average = outData(2);
Ic_average = outData(3);
Is_average = outData(4);

end
