# Impedance Sweep MATLAB Function

This folder stores versioned MATLAB Function code for impedance-sweep measurement.

## Current version

- **Version:** 1.0.0
- **File:** [v1_0_0/Average_Mean_Cycle.m](v1_0_0/Average_Mean_Cycle.m)
- **Status:** Pending Simulink compile and runtime verification.
- **Base sample time:** The function uses the externally supplied Ts; the intended setup discussed for this model is Ts = 1e-5 s.
- **Sweep-point dwell:** 8 cycles in the current model setup.
- **External inputs:** WAIT_CYCLES and AVG_CYCLES.

## Intended operation

1. Detect a new sweep point using PNUM.
2. Reset the moving-average state at the new point.
3. Wait for WAIT_CYCLES accumulated cycles.
4. Calculate a sample-by-sample moving average over AVG_CYCLES cycles.
5. Emit one Valid pulse per sweep point after the average window is full.

The window length is calculated as:

    Nwin = round(AVG_CYCLES/(Freq*Ts));

For the currently discussed minimum frequency of 1 Hz and Ts = 1e-5 s, a 5-cycle window requires about 500,000 samples. The current code reserves NMAX = 800000 samples per channel.

## Important integration notes

- Phase must be a continuously accumulated cycle count, with increment Freq*Ts each base sample. It must not reset at every phase wrap.
- Keep WAIT_CYCLES + AVG_CYCLES within the 8-cycle dwell time. The suggested initial test values are WAIT_CYCLES = 1 and AVG_CYCLES = 5.
- Valid is currently a one-base-sample pulse (width Ts). If the downstream To File block samples at 3*Ts, this pulse can be missed depending on sample-hit alignment. For reliable logging, use a base-rate capture or add a properly designed pulse-stretch/handshake stage; do not assume a one-Ts pulse is guaranteed to be sampled by a slower block.
- The code has not yet been compiled or run in the user's Simulink model. Treat it as a candidate version until that verification is completed.
- The persistent buffer uses approximately 25.6 MB for four double-precision channels at NMAX = 800000; adjust only after checking the lowest sweep frequency, averaging cycles, and code-generation constraints.

## Version history

See CHANGELOG.md.
