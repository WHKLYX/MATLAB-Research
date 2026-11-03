# Average_Mean_Cycle — v1.2.0

**Status:** Candidate backup; pending compile and runtime verification in the target Simulink model.  
**Date:** 2026-11-03  
**MATLAB Function:** `Average_Mean_Cycle.m`

## Purpose

This version measures the four signals used by the impedance sweep and produces one averaged result for each sweep-point number (`PNUM`). It retains complete-cycle batch averaging but removes the external `Phase` input. The cycle phase is accumulated internally from the current frequency and the externally supplied sample time.

## Function interface

```matlab
[Uc_average, Us_average, Ic_average, Is_average, Valid] = ...
    Average_Mean_Cycle(Uc, Us, Ic, Is, Freq, PNUM, EN, Ts, WAIT_CYCLES, AVG_CYCLES)
```

| Input | Meaning |
|---|---|
| `Uc`, `Us` | Voltage channels to be averaged |
| `Ic`, `Is` | Current channels to be averaged |
| `Freq` | Current perturbation frequency in Hz |
| `PNUM` | Sweep-point index; a change resets the measurement |
| `EN` | Measurement enable |
| `Ts` | Actual MATLAB Function execution interval in seconds |
| `WAIT_CYCLES` | Number of complete cycles discarded after a new point |
| `AVG_CYCLES` | Number of subsequent complete cycles included in the average |

The old external `Phase` input is not used in v1.2.0.

## Algorithm

1. When `EN` is low, reset the phase accumulator, cycle accumulators, outputs, and one-shot trigger state.
2. When `EN` rises, `PNUM` changes, or either cycle-count input changes, initialize a new measurement point.
3. Accumulate cycle phase on every function execution:
   `phaseFrac = phaseFrac + Freq * Ts`.
4. Accumulate the four input channels sample by sample within each complete perturbation cycle.
5. Discard the first `WAIT_CYCLES` complete cycles.
6. Sum the samples in the next `AVG_CYCLES` complete cycles and divide by the total number of samples.
7. When the requested average is complete, output `Valid = 1` for one MATLAB Function execution step and latch `measurementDone`.
8. Do not calculate or trigger again until the next `PNUM` or an `EN` reset.

This is finite complete-cycle batch averaging. It is not a continuously updating moving average.

## Current target model settings

| Item | Current target |
|---|---:|
| Powergui discrete sample time | `8e-8 s` |
| Model Settings → Solver → Fixed-step size | `8e-8 s` |
| MATLAB Function execution interval | `8e-8 s` |
| `Ts` input | `8e-8 s` |
| Maximum perturbation frequency considered | `2 kHz` |
| Maximum `Freq*Ts` at 2 kHz | `1.6e-4` |

**Important:** the code does not automatically detect or set the Simulink sample time. The MATLAB Function must actually execute at the interval passed through `Ts`. If the function executes at a different rate, the internal cycle phase will be wrong.

The implementation assumes `0 < Freq*Ts < 1`, so no more than one complete cycle boundary can be crossed in one function call. This is satisfied by the current target configuration.

## Sweep-point dwell and the extra 0.1 cycle

The measurement completes after:

```text
WAIT_CYCLES + AVG_CYCLES
```

The external sweep counter holds the current point for:

```text
WAIT_CYCLES + AVG_CYCLES + 0.1
```

The extra `0.1` cycle is an external dwell/transition margin. It is **not** added to the averaging window and is **not** implemented inside this MATLAB Function. After the average is complete, `measurementDone` keeps the function locked while the external counter finishes the remaining dwell time and changes `PNUM`.

For example, with `WAIT_CYCLES = 1` and `AVG_CYCLES = 2`, the result is ready after approximately 3 complete cycles; the external counter can retain the point for 3.1 cycles before advancing.

## Valid and Enabled Subsystem

- `Valid` is a one-execution-step pulse, nominally `Ts = 8e-8 s` wide when the MATLAB Function runs at the base rate.
- It is intended to trigger the downstream Enabled Subsystem once for each `PNUM`.
- The Enabled Subsystem and its capture path must be scheduled so they can see this base-rate pulse.
- A downstream logger or To File block running at a slower rate such as `3*Ts` may miss a one-`Ts` pulse depending on sample-hit alignment. If the capture path is slower, use a base-rate capture or a deliberate pulse-stretch/handshake stage; do not assume the short pulse will always be sampled.
- Confirm that the Enabled Subsystem records exactly one row per `PNUM`.

## Changes from v1.1.0

- Removed the external `Phase` input.
- Replaced external phase-difference tracking with an internal fractional-cycle accumulator driven by `Freq*Ts`.
- Added `measurementDone` to lock the measurement after the average is complete.
- Kept `WAIT_CYCLES` and `AVG_CYCLES` as external inputs.
- Kept complete-cycle batch accumulation and avoided a large sample-history buffer.
- Explicitly documented that the extra 0.1-cycle dwell margin belongs to the external sweep counter, not to the averaging function.

## Verification checklist

Before treating this version as stable, verify in the target model:

- [ ] MATLAB Function compiles successfully with the actual signal dimensions.
- [ ] Powergui, fixed-step solver, function execution interval, and `Ts` input are all consistent at `8e-8 s`.
- [ ] Test low-, mid-, and high-frequency sweep points, including the 2 kHz upper range.
- [ ] For each `PNUM`, the average becomes valid after the intended `WAIT_CYCLES + AVG_CYCLES` complete cycles.
- [ ] `Valid` is a single execution-step pulse and is not missed by the Enabled Subsystem.
- [ ] Exactly one record is saved per `PNUM`, including at high frequency.
- [ ] The external dwell uses `WAIT_CYCLES + AVG_CYCLES + 0.1` cycles.
- [ ] Compare impedance magnitude and phase with the previous v1.1.0 implementation under identical test conditions.

## Version retention

Do not overwrite earlier versions. Keep v1.0.0 and v1.1.0 for comparison and rollback. This v1.2.0 folder is a separate candidate snapshot.
