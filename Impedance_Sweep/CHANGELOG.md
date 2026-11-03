# Changelog — Impedance Sweep

## 2026-11-03 — v1.3.0

**Status: Final user-designated version for the current impedance-sweep workflow.**  
**Verification note:** Source and documentation have been archived. Simulink compilation and end-to-end runtime verification have not been independently performed as part of this GitHub update.

### Final source

- `v1_3_0/Average_Mean_Cycle.m`
- `v1_3_0/README.md`

The MATLAB Function body follows the exact version supplied by the user in the 2026-11-03 conversation. Only version/date/status comments were added to the file header; the algorithm and input/output interface were not otherwise changed.

### Recorded behavior and settings

- 10 inputs: `Uc`, `Us`, `Ic`, `Is`, `Freq`, `PNUM`, `EN`, `Ts`, `WAIT_CYCLES`, `AVG_CYCLES`.
- 5 outputs: `Uc_average`, `Us_average`, `Ic_average`, `Is_average`, `Valid`.
- The external `Phase` input is removed.
- The sweep controller changes `PNUM` and updates `Freq` together; `PNUM` is the new-point reset signal.
- Internal phase accumulation uses `Freq*Ts`.
- The first `WAIT_CYCLES` complete cycles are discarded; the following `AVG_CYCLES` complete cycles are accumulated and averaged.
- No large sample-history buffer or `NMAX` allocation is used.
- `Valid` is high for one MATLAB Function execution only, once per `PNUM`.
- `measurementDone` locks the measurement after completion until the next `PNUM` or `EN` reset.
- The external sweep counter provides the extra 0.1-cycle margin. The total dwell is `WAIT_CYCLES + AVG_CYCLES + 0.1`; the extra 0.1 cycle is not averaged and does not extend `Valid`.

### Target sweep configuration

- Sweep range: 1 Hz to 100 kHz.
- Powergui discrete sample time: `8e-8 s`.
- Model fixed-step size: `8e-8 s`.
- MATLAB Function actual execution interval: `8e-8 s`.
- `Ts` input: `8e-8 s`.
- At 100 kHz, `Freq*Ts = 0.008`, corresponding to 125 samples per perturbation cycle.
- The implementation assumes `0 < Freq*Ts < 1`.

**Important integration note:** setting the `Ts` input does not configure the MATLAB Function execution rate. The block must actually execute at the supplied `Ts`. Also ensure the downstream Enabled Subsystem/capture path can observe the one-execution-step `Valid` pulse; a slower logger such as `3*Ts` may miss it depending on sample-hit alignment.

### Final-version designation

v1.3.0 is the user-designated final/recommended source for the current 1 Hz–100 kHz sweep workflow. Earlier versions remain unchanged for rollback and comparison. This designation records the user's chosen final code; it must not be interpreted as a claim that this GitHub operation compiled or ran the Simulink model.

---

All entries are versioned. Previous versions are retained; do not overwrite them.

## 2026-11-03 — v1.2.0

**Status: Candidate backup; pending Simulink compile and runtime verification. Not designated stable.**

### Motivation

The v1.1.0 complete-cycle averaging implementation used an external `Phase` input. The latest model arrangement is intended to use the actual discrete base step directly, with `Ts` supplied to the MATLAB Function. The new version therefore accumulates perturbation phase internally from `Freq*Ts`. It also needs to hold the measurement complete after one result is ready, while the external sweep counter finishes its additional 0.1-cycle dwell margin.

### Changes

- Removed the external `Phase` input from the function interface.
- Added internal fractional-cycle accumulation:
  `phaseFrac = phaseFrac + Freq*Ts`.
- Kept `WAIT_CYCLES` and `AVG_CYCLES` as external scalar inputs.
- Kept complete-cycle batch accumulation; no large sample-history buffer or `NMAX` allocation is used.
- Added `measurementDone` to lock the calculation after the requested average is complete.
- Kept one one-execution-step `Valid` pulse per `PNUM`; it is reset only when a new point is detected or `EN` is disabled.
- Documented the external sweep-point dwell as `WAIT_CYCLES + AVG_CYCLES + 0.1`. The extra 0.1 cycle is not part of the average and is not implemented inside the MATLAB Function.

### Current target configuration

- Powergui discrete sample time: `8e-8 s`.
- Model Settings → Solver → Fixed-step size: `8e-8 s`.
- MATLAB Function execution interval: must be `8e-8 s`.
- `Ts` input: `8e-8 s`.
- Maximum perturbation frequency considered: `2 kHz`.
- At 2 kHz, `Freq*Ts = 1.6e-4`, which is less than one cycle per function execution.

**Important:** the code does not automatically detect the Simulink execution interval. The MATLAB Function must actually execute at the same interval supplied through `Ts`. The implementation assumes `0 < Freq*Ts < 1`.

### Valid / Enabled Subsystem note

`Valid` is high for one MATLAB Function execution step. The downstream Enabled Subsystem and capture path must be able to see a base-rate pulse. A slower To File/logging sample time such as `3*Ts` may miss the pulse depending on sample-hit alignment. Verify one saved record per `PNUM`; use a base-rate capture or a deliberate pulse-stretch/handshake stage if the capture path is slower.

### Verification still required

- Compile the MATLAB Function in the target Simulink model and confirm signal dimensions.
- Confirm Powergui, fixed-step solver, MATLAB Function execution interval, and `Ts` are all consistent at `8e-8 s`.
- Test representative low-, mid-, and high-frequency points, including 2 kHz.
- Confirm that the average is ready after `WAIT_CYCLES + AVG_CYCLES` complete cycles.
- Confirm that `Valid` triggers the Enabled Subsystem exactly once per `PNUM`.
- Confirm exactly one logged result per sweep point, including in the high-frequency range.
- Confirm that the external counter retains each point for `WAIT_CYCLES + AVG_CYCLES + 0.1` cycles.
- Compare impedance magnitude and phase with v1.1.0 under identical conditions.

## 2026-11-03 — v1.1.0

**Status: Pending Simulink compile/runtime verification. Not designated stable.**

### Motivation

The v1.0.0 implementation allocated a fixed four-channel sample-history buffer. Increasing `NMAX` to very large values can request excessive memory and cause model initialization or memory-allocation failures. The user asked to remove this buffer-based limit.

### Changes

- Removed `NMAX`, the fixed-size `buffer`, and the circular-buffer index.
- Replaced sample-by-sample circular moving-average storage with complete-cycle batch accumulation.
- Retained externally supplied `WAIT_CYCLES` and `AVG_CYCLES`.
- Retained PNUM-based sweep-point reset.
- Ignore the first `WAIT_CYCLES` complete cycles, then accumulate samples over the next `AVG_CYCLES` complete cycles.
- Calculate the output as total accumulated sample sum divided by total sample count, rather than averaging cycle means with equal cycle weights.
- Retained one `Valid` pulse per PNUM after the requested number of complete averaging cycles has been accumulated.

### Algorithm change — important

v1.0.0 performs a sample-by-sample sliding average using a circular sample buffer. v1.1.0 does **not** perform a continuously sliding average: it accumulates a finite batch of complete cycles and produces the final average once that batch is complete. Therefore, output behavior and Valid timing are not expected to be identical at every sample. Compare the resulting impedance magnitude and phase against v1.0.0 and the original Mean block.

### Verification still required

- Compile the MATLAB Function block in the target Simulink model.
- Confirm that `Phase` is a scalar, continuously accumulated cycle count.
- Test representative low-, mid-, and high-frequency points.
- Confirm that `WAIT_CYCLES + AVG_CYCLES` fits within the 8-cycle dwell time.
- Confirm that each PNUM produces exactly one logged result.
- Check the one-`Ts` `Valid` pulse against the downstream logging sample time. A logger running at `3*Ts` may miss a one-`Ts` pulse depending on sample-hit alignment.
- Compare magnitude and phase against v1.0.0 under identical injection and averaging conditions.

## 2026-11-02 — v1.0.0

**Status: Pending Simulink compile/runtime verification.**

### Recorded issues from the preceding chat iteration

1. **MATLAB Function code-generation / character-encoding error**
   - The previous code used a Chinese-language message in an `assert`.
   - The Simulink MATLAB Function code-generation path reported a GBK character-conversion problem.
2. **Phase signal dimension diagnostic**
   - Simulink reported a port-width/dimension diagnostic on the `Phase` signal.
   - v1.0.0 explicitly reads the first element of scalar-valued inputs, including `Phase(1)`. This is defensive scalarization; model-side dimensions still need to be checked if the diagnostic persists.
3. **Insufficient maximum averaging buffer**
   - The previous `NMAX = 200000` only covered a 2-cycle window at 1 Hz with `Ts = 1e-5 s`.
   - v1.0.0 increased `NMAX` to 800000, but this fixed allocation still consumes memory and is removed in v1.1.0.

### Changes in v1.0.0

- Added external inputs `WAIT_CYCLES` and `AVG_CYCLES`.
- Retained PNUM-based sweep-point reset.
- Retained sample-by-sample moving-average update.
- Changed the assert message to English to avoid the reported encoding issue.
- Added scalarization for the input signals.
- Increased the fixed buffer capacity to 800,000 samples per channel.
- Kept one `Valid` pulse per sweep point.

### Verification still required

- Compile the MATLAB Function block in the target Simulink model.
- Confirm that `Phase` is scalar and continuously accumulates cycles.
- Test the 1 Hz point with the selected `WAIT_CYCLES` and `AVG_CYCLES`.
- Confirm that each PNUM produces exactly one logged point.
- Check the interaction between the one-`Ts` `Valid` pulse and the downstream To File sample time. With a To File sample time of `3*Ts`, this pulse may be missed.

### Known limitation

The v1.0.0 persistent buffer uses approximately 25.6 MB per MATLAB Function instance for the four-channel double buffer at `NMAX = 800000`. v1.1.0 removes this sample-history buffer.
