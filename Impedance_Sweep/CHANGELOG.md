# Changelog — Impedance Sweep

All entries are versioned. Previous versions are retained; do not overwrite them.

## 2026-11-03 — v1.1.0

**Status: Pending Simulink compile/runtime verification. Not designated stable.**

### Motivation

The v1.0.0 implementation allocated a fixed four-channel sample-history buffer. Increasing \`NMAX\` to very large values can request excessive memory and cause model initialization or memory-allocation failures. The user asked to remove this buffer-based limit.

### Changes

- Removed \`NMAX\`, the fixed-size \`buffer\`, and the circular-buffer index.
- Replaced sample-by-sample circular moving-average storage with complete-cycle batch accumulation.
- Retained externally supplied \`WAIT_CYCLES\` and \`AVG_CYCLES\`.
- Retained PNUM-based sweep-point reset.
- Ignore the first \`WAIT_CYCLES\` complete cycles, then accumulate samples over the next \`AVG_CYCLES\` complete cycles.
- Calculate the output as total accumulated sample sum divided by total sample count, rather than averaging cycle means with equal cycle weights.
- Retained one \`Valid\` pulse per PNUM after the requested number of complete averaging cycles has been accumulated.

### Algorithm change — important

v1.0.0 performs a sample-by-sample sliding average using a circular sample buffer. v1.1.0 does **not** perform a continuously sliding average: it accumulates a finite batch of complete cycles and produces the final average once that batch is complete. Therefore, output behavior and Valid timing are not expected to be identical at every sample. Compare the resulting impedance magnitude and phase against v1.0.0 and the original Mean block.

### Verification still required

- Compile the MATLAB Function block in the target Simulink model.
- Confirm that \`Phase\` is a scalar, continuously accumulated cycle count.
- Test representative low-, mid-, and high-frequency points.
- Confirm that \`WAIT_CYCLES + AVG_CYCLES\` fits within the 8-cycle dwell time.
- Confirm that each PNUM produces exactly one logged result.
- Check the one-\`Ts\` \`Valid\` pulse against the downstream logging sample time. A logger running at \`3*Ts\` may miss a one-\`Ts\` pulse depending on sample-hit alignment.
- Compare magnitude and phase against v1.0.0 under identical injection and averaging conditions.

## 2026-11-02 — v1.0.0

**Status: Pending Simulink compile/runtime verification.**

### Recorded issues from the preceding chat iteration

1. **MATLAB Function code-generation / character-encoding error**
   - The previous code used a Chinese-language message in an \`assert\`.
   - The Simulink MATLAB Function code-generation path reported a GBK character-conversion problem.
2. **Phase signal dimension diagnostic**
   - Simulink reported a port-width/dimension diagnostic on the \`Phase\` signal.
   - v1.0.0 explicitly reads the first element of scalar-valued inputs, including \`Phase(1)\`. This is defensive scalarization; model-side dimensions still need to be checked if the diagnostic persists.
3. **Insufficient maximum averaging buffer**
   - The previous \`NMAX = 200000\` only covered a 2-cycle window at 1 Hz with \`Ts = 1e-5 s\`.
   - v1.0.0 increased \`NMAX\` to 800000, but this fixed allocation still consumes memory and is removed in v1.1.0.

### Changes in v1.0.0

- Added external inputs \`WAIT_CYCLES\` and \`AVG_CYCLES\`.
- Retained PNUM-based sweep-point reset.
- Retained sample-by-sample moving-average update.
- Changed the assert message to English to avoid the reported encoding issue.
- Added scalarization for the input signals.
- Increased the fixed buffer capacity to 800,000 samples per channel.
- Kept one \`Valid\` pulse per sweep point.

### Verification still required

- Compile the MATLAB Function block in the target Simulink model.
- Confirm that \`Phase\` is scalar and continuously accumulates cycles.
- Test the 1 Hz point with the selected \`WAIT_CYCLES\` and \`AVG_CYCLES\`.
- Confirm that each PNUM produces exactly one logged point.
- Check the interaction between the one-\`Ts\` \`Valid\` pulse and the downstream To File sample time. With a To File sample time of \`3*Ts\`, this pulse may be missed.

### Known limitation

The v1.0.0 persistent buffer uses approximately 25.6 MB per MATLAB Function instance for the four-channel double buffer at \`NMAX = 800000\`. v1.1.0 removes this sample-history buffer.
