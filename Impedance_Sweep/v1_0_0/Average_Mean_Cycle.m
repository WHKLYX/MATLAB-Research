function [Uc_average, Us_average, Ic_average, Is_average, Valid] = ...
    Average_Mean_Cycle(Uc, Us, Ic, Is, Freq, PNUM, EN, Phase, Ts, WAIT_CYCLES, AVG_CYCLES)
%#codegen
%
% Version: 1.0.0
% Date: 2026-11-02
%
% Impedance-sweep moving average, updated at every base sample.
%
% WAIT_CYCLES : number of cycles to wait after a new sweep point
% AVG_CYCLES  : number of cycles included in the moving-average window
%
% Phase must be a continuously accumulated cycle count:
% Phase(k) = Phase(k-1) + Freq * Ts
%
% Notes:
% 1. The averaging window is Nwin = round(AVG_CYCLES/(Freq*Ts)).
% 2. Valid is a one-base-sample pulse (one Ts wide).
% 3. Keep WAIT_CYCLES + AVG_CYCLES within the dwell cycles of each point.
% 4. NMAX supports up to 8 average cycles at 1 Hz with Ts = 1e-5 s.

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

%% ===== 2. Maximum buffer length =====

NMAX = 800000;

%% ===== 3. Persistent states =====

persistent initialized
persistent prevEN prevPNUM
persistent prevWaitN prevAvgN
persistent phaseStart

persistent buffer
persistent sumData outData

persistent Nwin
persistent idx count
persistent windowReady validSent

%% ===== 4. Initialization =====

if isempty(initialized)

    initialized = true;

    prevEN = false;
    prevPNUM = pnum;

    prevWaitN = waitN;
    prevAvgN = avgN;

    phaseStart = phaseValue;

    buffer = zeros(NMAX,4);

    sumData = zeros(1,4);
    outData = zeros(1,4);

    Nwin = 1;

    idx = 1;
    count = 0;

    windowReady = false;
    validSent = false;

end

%% ===== 5. Valid defaults to zero =====

Valid = 0;

%% ===== 6. Reset when disabled =====

if en <= 0.5

    prevEN = false;
    prevPNUM = pnum;

    prevWaitN = waitN;
    prevAvgN = avgN;

    phaseStart = phaseValue;

    idx = 1;
    count = 0;

    sumData = zeros(1,4);
    outData = zeros(1,4);

    windowReady = false;
    validSent = false;

else

    %% ===== 7. Detect a new sweep point =====

    pnumChanged = abs(pnum-prevPNUM) > 0.5;

    parameterChanged = ...
        (waitN ~= prevWaitN) || ...
        (avgN ~= prevAvgN);

    newPoint = (~prevEN) || ...
               pnumChanged || ...
               parameterChanged;

    if newPoint

        phaseStart = phaseValue;

        idx = 1;
        count = 0;

        sumData = zeros(1,4);
        outData = zeros(1,4);

        windowReady = false;
        validSent = false;

    elseif ~windowReady

        %% ===== 8. Calculate moving-average window length =====

        if ~isnan(freq) && ~isinf(freq) && ...
           ~isnan(ts) && ~isinf(ts) && ...
           freq > 0 && ts > 0

            Nrequired = round(avgN/(freq*ts));

            if Nrequired >= 1

                assert(Nrequired <= NMAX, ...
                    'Window exceeds NMAX. Increase NMAX.');

                Nwin = Nrequired;

                windowReady = true;

            end

        end

    end

    %% ===== 9. Moving-average calculation =====

    if windowReady

        elapsedCycles = phaseValue - phaseStart;

        %% Phase-reset protection

        if elapsedCycles < -1e-9

            phaseStart = phaseValue;

            idx = 1;
            count = 0;

            sumData = zeros(1,4);
            outData = zeros(1,4);

            windowReady = false;
            validSent = false;

        elseif elapsedCycles >= waitN

            currentData = [uc, us, ic, is];

            %% Fill the window

            if count < Nwin

                count = count + 1;

                sumData = sumData + currentData;

            else

                %% Remove the oldest sample and add the newest sample

                sumData = sumData ...
                        - buffer(idx,:) ...
                        + currentData;

            end

            %% Update circular buffer

            buffer(idx,:) = currentData;

            idx = idx + 1;

            if idx > Nwin
                idx = 1;
            end

            %% ===== 10. Output moving average =====

            if count >= Nwin

                outData = sumData/Nwin;

                %% ===== 11. One Valid pulse per sweep point =====

                if ~validSent && ...
                   elapsedCycles >= waitN + avgN

                    Valid = 1;

                    validSent = true;

                end

            end

        end

    end

    %% ===== 12. Update sweep states =====

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
