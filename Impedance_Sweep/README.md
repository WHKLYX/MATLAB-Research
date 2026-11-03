# Impedance Sweep MATLAB Function

This folder stores versioned MATLAB Function code for impedance-sweep measurement. **Do not overwrite older versions**; each meaningful algorithm or interface change is stored in a separate version directory.

## Final user-designated version: v1.3.0

- **File:** [v1_3_0/Average_Mean_Cycle.m](v1_3_0/Average_Mean_Cycle.m)
- **Version notes:** [v1_3_0/README.md](v1_3_0/README.md)
- **Status:** Final/recommended source designated by the user for the current workflow. The GitHub backup itself has not independently compiled or run the Simulink model.
- **Target sweep range:** 1 Hz to 100 kHz.
- **Target base sample time:** `Ts = 8e-8 s`.
- **External cycle-count inputs:** `WAIT_CYCLES` and `AVG_CYCLES`.
- **New sweep-point detection:** `PNUM` changes; the sweep controller updates `Freq` together with `PNUM`.
- **Internal phase:** accumulated using `Freq*Ts`; no external `Phase` input.
- **Sweep-point dwell:** `WAIT_CYCLES + AVG_CYCLES + 0.1` cycles, with the extra 0.1 cycle handled by the external sweep counter.

### v1.3.0 algorithm

1. Reset the internal phase and accumulators when `EN` is disabled or a new `PNUM` is detected.
2. Accumulate cycle phase internally using `Freq*Ts`.
3. Ignore the first `WAIT_CYCLES` complete cycles.
4. Accumulate the four channels over the next `AVG_CYCLES` complete cycles.
5. Divide the total sample sums by the total sample count.
6. Output one `Valid` pulse for one MATLAB Function execution step.
7. Latch `measurementDone` so the same `PNUM` cannot trigger again. Reset on the next `PNUM` or when `EN` is disabled.

The extra 0.1-cycle dwell margin is not part of the average and is not implemented inside the MATLAB Function.

### Important integration notes

- The MATLAB Function must actually execute at the same interval supplied through `Ts`. The current target is Powergui discrete sample time = fixed-step solver size = function execution interval = `8e-8 s`.
- The code assumes `0 < Freq*Ts < 1`. At 100 kHz and `Ts=8e-8 s`, `Freq*Ts=0.008`, or 125 samples per cycle.
- `Valid` is a one-execution-step pulse. The Enabled Subsystem and capture path must be able to see a base-rate pulse.
- A logger running at a slower rate such as `3*Ts` may miss a one-`Ts` pulse depending on sample-hit alignment. Verify exactly one saved record per `PNUM`.
- At 1 Hz, one perturbation cycle contains 12,500,000 base-rate samples. The code avoids a large history buffer, but the low-frequency portion can still require substantial simulation time.
- The code does not infer the solver step automatically. If the MATLAB Function execution rate and the `Ts` input differ, the phase accumulation will be incorrect.

## Previous versions

- [v1.2.0/Average_Mean_Cycle.m](v1_2_0/Average_Mean_Cycle.m): internal phase accumulation and one-shot completion lock, originally documented for a maximum sweep frequency of 2 kHz. Retained for comparison and rollback.
- [v1.1.0/Average_Mean_Cycle.m](v1_1_0/Average_Mean_Cycle.m): complete-cycle batch accumulation using an external `Phase` input; no large sample-history buffer. Retained for comparison and rollback.
- [v1.0.0/Average_Mean_Cycle.m](v1_0_0/Average_Mean_Cycle.m): sample-by-sample moving average with a fixed circular buffer. Retained for comparison and rollback.

## Version history

See [CHANGELOG.md](CHANGELOG.md) for the motivation, algorithm differences, known issues, and verification notes for each version.
