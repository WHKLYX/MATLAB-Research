function [Uc_average, Us_average, Ic_average, Is_average, Valid] = ...
    Average_Mean_Cycle(Uc, Us, Ic, Is, Freq, PNUM, EN, Ts, WAIT_CYCLES, AVG_CYCLES)
%#codegen
%
% Version: 1.2.0
% Date: 2026-11-03
% Status: Candidate; pending Simulink compile and runtime verification.
%
% Impedance sweep: complete-cycle batch averaging using the actual Ts input.
%
% WAIT_CYCLES : number of complete cycles to wait after a new sweep point
% AVG_CYCLES  : number of complete cycles to accumulate for the average
%
% The cycle phase is accumulated internally using Freq * Ts.
% No external Phase input and no large sample-history buffer are required.
%
% One Valid pulse (one MATLAB Function execution step) is generated per PNUM.
% After the average is complete, measurementDone locks the measurement until
% the next PNUM or EN reset.
%
% The extra 0.1-cycle dwell margin is implemented by the external sweep
% counter. It is not included in the averaging calculation.
%
% The MATLAB Function must execute at the same base sample time supplied
% through Ts. The current target configuration is Ts = 8e-8 s.

%% ===== 1. Scalarize inputs =====

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

%% ===== 2. Persistent states =====

persistent initialized
persistent prevEN prevPNUM
persistent prevWaitN prevAvgN

persistent phaseFrac completedCycles

persistent cycleSum cycleCount
persistent totalSum totalCount
persistent avgCycleCount

persistent outData
persistent validSent measurementDone

%% ===== 3. Initialization =====

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

%% ===== 4. Valid defaults to zero =====

% Valid is high for one MATLAB Function execution step only.
Valid = 0;

%% ===== 5. Reset when disabled =====

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

    %% ===== 6. Detect a new sweep point =====

    pnumChanged = abs(pnum-prevPNUM) > 0.5;

    parameterChanged = ...
        (waitN ~= prevWaitN) || ...
        (avgN ~= prevAvgN);

    newPoint = (~prevEN) || ...
               pnumChanged || ...
               parameterChanged;

    if newPoint

        % Reset cycle phase and all accumulators for the new point.
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

    %% ===== 7. Internal cycle-phase accumulation =====

    % The current sweep range (up to 2 kHz) and Ts=8e-8 s give
    % Freq*Ts <= 1.6e-4, so at most one cycle boundary is crossed per call.
    phaseStep = freq * ts;

    if phaseStep > 0 && phaseStep < 1 && ...
            ~measurementDone

        %% Accumulate the current sample

        cycleSum(1) = cycleSum(1) + uc;
        cycleSum(2) = cycleSum(2) + us;
        cycleSum(3) = cycleSum(3) + ic;
        cycleSum(4) = cycleSum(4) + is;

        cycleCount = cycleCount + 1;

        %% Accumulate phase using the externally supplied Ts

        phaseFrac = phaseFrac + phaseStep;

        %% ===== 8. Detect a completed cycle =====

        if phaseFrac >= 1.0

            phaseFrac = phaseFrac - 1.0;

            completedCycles = completedCycles + 1;

            %% ===== 9. Skip the waiting cycles =====

            if completedCycles > waitN && cycleCount > 0

                % Add the current complete cycle to the averaging batch.
                totalSum = totalSum + cycleSum;
                totalCount = totalCount + cycleCount;

                avgCycleCount = avgCycleCount + 1;

                %% ===== 10. Complete the requested average =====

                if avgCycleCount >= avgN && totalCount > 0

                    outData = totalSum / totalCount;

                    %% ===== 11. Generate one Valid pulse =====

                    if ~validSent

                        Valid = 1;
                        validSent = true;

                        % Lock measurement until the next PNUM or EN reset.
                        measurementDone = true;

                    end

                end

            end

            %% Start collecting the next cycle

            cycleSum = zeros(1,4);
            cycleCount = 0;

        end

    end

    %% ===== 12. Update sweep-point states =====

    prevEN = true;
    prevPNUM = pnum;

    prevWaitN = waitN;
    prevAvgN = avgN;

end

%% ===== 13. Outputs =====

Uc_average = outData(1);
Us_average = outData(2);
Ic_average = outData(3);
Is_average = outData(4);

end
