# Impedance Sweep MATLAB Function

This folder stores versioned MATLAB Function code for impedance-sweep measurement. **Do not overwrite older versions**; each meaningful algorithm or interface change is stored in a separate version directory.

## Current candidate: v1.2.0

- **File:** [v1_2_0/Average_Mean_Cycle.m](v1_2_0/Average_Mean_Cycle.m)
- **Version notes:** [v1_2_0/README.md](v1_2_0/README.md)
- **Status:** Backed up; pending compile and runtime verification in the target Simulink model. Not designated stable.
- **Target base sample time:** `Ts = 8e-8 s`.
- **Maximum perturbation frequency considered:** `2 kHz`.
- **External cycle-count inputs:** `WAIT_CYCLES` and `AVG_CYCLES`.
- **Sweep-point dwell:** `WAIT_CYCLES + AVG_CYCLES + 0.1` cycles, with the extra 0.1 cycle handled by the external sweep counter.

### v1.2.0 algorithm

1. Detect a new sweep point using `PNUM`; reset the internal phase and accumulators.
2. Accumulate fractional cycle phase internally using `Freq*Ts`; there is no external `Phase` input.
3. Ignore the first `WAIT_CYCLES` complete cycles.
4. Accumulate the four channels over the next `AVG_CYCLES` complete cycles.
5. Divide the total sample sums by the total sample count.
6. Output one `Valid` pulse for one MATLAB Function execution step.
7. Latch `measurementDone` so the same `PNUM` cannot calculate or trigger again. Reset on the next `PNUM` or when `EN` is disabled.

The extra 0.1-cycle dwell margin is not part of the average and is not implemented inside the MATLAB Function.

### Important integration notes

- The MATLAB Function must actually execute at the same interval supplied through `Ts`. The current target is Powergui discrete sample time = fixed-step solver size = function execution interval = `8e-8 s`.
- The code assumes `0 < Freq*Ts < 1`. At 2 kHz and `Ts=8e-8 s`, `Freq*Ts=1.6e-4`.
- `Valid` is a one-execution-step pulse. The Enabled Subsystem and capture path must be able to see a base-rate pulse.
- A logger running at a slower rate such as `3*Ts` may miss a one-`Ts` pulse depending on sample-hit alignment. Verify exactly one saved record per `PNUM`.
- The code does not infer the solver step automatically. If the MATLAB Function execution rate and the `Ts` input differ, the phase accumulation will be incorrect.
- Compile and test low-, mid-, and high-frequency points before treating v1.2.0 as stable.

## Previous versions

- [v1.1.0/Average_Mean_Cycle.m](v1_1_0/Average_Mean_Cycle.m): complete-cycle batch accumulation using an external `Phase` input; no large sample-history buffer. Retained for comparison and rollback.
- [v1.0.0/Average_Mean_Cycle.m](v1_0_0/Average_Mean_Cycle.m): sample-by-sample moving average with a fixed circular buffer. Retained for comparison and rollback.

## Version history

See [CHANGELOG.md](CHANGELOG.md) for the motivation, algorithm differences, known issues, and verification checklist for each version.
