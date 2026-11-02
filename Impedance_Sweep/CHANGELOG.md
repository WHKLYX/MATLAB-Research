# Changelog — Impedance Sweep

All entries are versioned. Previous versions are retained; do not overwrite a released version.

## 2026-11-02 — v1.0.0

**Status: Pending Simulink compile/runtime verification.**

### Recorded issues from the preceding chat iteration

1. **MATLAB Function code-generation / character-encoding error**
   - The previous code used a Chinese-language message in an assert.
   - The Simulink MATLAB Function code-generation path reported a GBK character-conversion problem.
2. **Phase signal dimension diagnostic**
   - Simulink reported a port-width/dimension diagnostic on the Phase signal.
   - The new version explicitly reads the first element of scalar-valued inputs, including Phase(1). This is a defensive scalarization; the model-side signal dimensions still need to be checked if the diagnostic persists.
3. **Insufficient maximum averaging buffer**
   - The previous NMAX = 200000 only covered a 2-cycle window at 1 Hz with Ts = 1e-5 s.
   - The new version uses NMAX = 800000, sufficient for up to 8 averaging cycles at 1 Hz and this sample time.

### Changes in v1.0.0

- Added external inputs WAIT_CYCLES and AVG_CYCLES.
- Retained PNUM-based sweep-point reset.
- Retained sample-by-sample moving-average update.
- Changed the assert message to English to avoid the reported encoding issue.
- Added scalarization for the input signals.
- Increased the fixed buffer capacity to 800,000 samples per channel.
- Kept one Valid pulse per sweep point.

### Verification still required

- Compile the MATLAB Function block in the target Simulink model.
- Confirm that Phase is scalar and continuously accumulates cycles.
- Test the 1 Hz point with the selected WAIT_CYCLES and AVG_CYCLES.
- Confirm that each PNUM produces exactly one logged point.
- Check the interaction between the one-Ts Valid pulse and the downstream To File sample time. With a To File sample time of 3*Ts, a one-Ts pulse may be missed.

### Known limitation

The version increases persistent memory use to approximately 25.6 MB per MATLAB Function instance for the four-channel double buffer. Performance and memory impact must be checked in the actual model.
