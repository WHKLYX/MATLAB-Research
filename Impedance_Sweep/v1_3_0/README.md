# Average_Mean_Cycle — v1.3.0

**Version status: Final user-designated version for the current impedance-sweep workflow.**  
**Archived:** 2026-11-03  
**Verification note:** This exact version has been saved to GitHub. Simulink compilation and end-to-end runtime verification must still be completed in the user's target model; this repository update does not claim those tests have been run.

## Files

- [Average_Mean_Cycle.m](Average_Mean_Cycle.m) — complete MATLAB Function source.
- This README — interface, timing, and integration notes.

## Function interface

```matlab
[Uc_average, Us_average, Ic_average, Is_average, Valid] = ...
    Average_Mean_Cycle(Uc, Us, Ic, Is, Freq, PNUM, EN, Ts, WAIT_CYCLES, AVG_CYCLES)
```

There are 10 inputs and 5 outputs. The external `Phase` input used by earlier versions has been removed.

| Input | Meaning |
|---|---|
| `Uc`, `Us` | Voltage measurement channels |
| `Ic`, `Is` | Current measurement channels |
| `Freq` | Current sweep perturbation frequency in Hz |
| `PNUM` | Sweep-point index; its change resets the measurement |
| `EN` | Measurement enable |
| `Ts` | Actual MATLAB Function execution interval in seconds |
| `WAIT_CYCLES` | Number of complete cycles discarded before averaging |
| `AVG_CYCLES` | Number of subsequent complete cycles included in the average |

## Algorithm

1. When `EN <= 0.5`, reset the phase accumulator, cycle counters, data accumulators, output values, and one-shot Valid state.
2. When `PNUM` changes, treat it as the start of a new sweep point and reset the measurement state. In the current sweep controller, `Freq` updates together with the `PNUM` change.
3. Accumulate cycle phase internally on every function execution using `phaseFrac = phaseFrac + Freq*Ts`.
4. Accumulate the four measurement channels sample by sample over each complete perturbation cycle.
5. Discard the first `WAIT_CYCLES` complete cycles.
6. Accumulate the next `AVG_CYCLES` complete cycles.
7. Calculate each output as its total sample sum divided by the total number of samples accumulated across the averaging cycles.
8. When the requested average is complete, set `Valid = 1` for that single MATLAB Function execution and set `measurementDone = true`.
9. Keep the measurement locked until the next `PNUM` or until `EN` is disabled. This prevents repeated Valid pulses for the same sweep point.

This is complete-cycle batch averaging. It is not a continuously updating moving average and it does not use a large sample-history buffer.

## Sweep-point dwell and extra 0.1 cycle

The MATLAB Function performs the measurement over:

```text
WAIT_CYCLES + AVG_CYCLES
```

The external sweep counter holds each point for:

```text
WAIT_CYCLES + AVG_CYCLES + 0.1
```

The extra `0.1` cycle is managed **outside** this MATLAB Function. It is a save/transition margin only:

- It is not included in the averaging data.
- It does not extend the `Valid` pulse.
- After the average is ready, `measurementDone` locks the function while the external counter completes the extra dwell and advances `PNUM`.

If the external counter counts base-rate samples, its dwell count can be calculated as:

```matlab
EXTRA_CYCLES = 0.1;
TOTAL_DWELL_CYCLES = WAIT_CYCLES + AVG_CYCLES + EXTRA_CYCLES;
N_DWELL = ceil(TOTAL_DWELL_CYCLES / (Freq * Ts));
```

Use one dwell-timing method only; do not apply the extra 0.1 cycle twice.

## Target operating range and sample-time assumptions

| Item | Target setting |
|---|---:|
| Sweep frequency range | 1 Hz to 100 kHz |
| Powergui discrete sample time | `8e-8 s` |
| Model fixed-step size | `8e-8 s` |
| MATLAB Function actual execution interval | `8e-8 s` |
| `Ts` input | `8e-8 s` |
| `Freq*Ts` at 1 Hz | `8e-8` |
| `Freq*Ts` at 100 kHz | `0.008` |
| Samples per cycle at 100 kHz | `125` |

The implementation requires `0 < Freq*Ts < 1`. This is satisfied over 1 Hz to 100 kHz for `Ts=8e-8 s`.

**Critical sample-time requirement:** the MATLAB Function must actually execute once every `Ts`. Supplying `Ts=8e-8` as an input does not itself configure the block execution rate. The Powergui step, fixed-step solver, MATLAB Function execution rate, and `Ts` input must be consistent.

At 1 Hz, one cycle contains 12,500,000 base-rate samples. A single low-frequency sweep point can therefore require substantial simulation time. The code avoids a large history buffer, but it does not reduce the number of fixed-step solver executions.

## Valid and downstream Enabled Subsystem

- `Valid` defaults to zero on every function invocation.
- It is high for one MATLAB Function execution only when the requested average first completes.
- It is intended to enable the downstream Enabled Subsystem once per `PNUM`.
- Do not stretch `Valid` to cover the extra 0.1 cycle: a level-enabled subsystem could execute repeatedly and save duplicate records.
- The Enabled Subsystem and its capture path must be able to observe the one-base-step pulse. If a downstream logging/capture block runs more slowly than `Ts` (for example, `3*Ts`), it may miss the pulse depending on sample-hit alignment. Use a base-rate capture path or a deliberate handshake/pulse-capture stage if needed.
- Confirm exactly one saved record for every `PNUM`.

## Version history

- **v1.3.0 — this version:** user-designated final version for the current workflow; 1 Hz–100 kHz target range; PNUM-based reset; internal `Freq*Ts` phase accumulation; externally supplied wait/average cycle counts; one-execution-step Valid pulse; extra 0.1 cycle handled by the external sweep counter.
- **v1.2.0:** internal phase accumulation and one-shot completion lock, originally documented for a maximum sweep frequency of 2 kHz.
- **v1.1.0:** complete-cycle batch accumulation using an external `Phase` input.
- **v1.0.0:** sample-by-sample moving average using a fixed circular buffer.

Older versions are retained for comparison and rollback. See [the impedance-sweep changelog](../CHANGELOG.md) for detailed historical notes.
