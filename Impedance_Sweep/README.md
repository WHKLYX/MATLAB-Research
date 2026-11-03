# Impedance Sweep MATLAB Function

This folder stores versioned MATLAB Function code for impedance-sweep measurement.

## Current candidate: v1.1.0

- **File:** [v1_1_0/Average_Mean_Cycle.m](v1_1_0/Average_Mean_Cycle.m)
- **Status:** Pending Simulink compile and runtime verification; not yet designated stable.
- **Base sample time:** Externally supplied \`Ts\`; the model setup discussed uses \`Ts = 1e-5 s\`.
- **Sweep-point dwell:** 8 cycles in the current model setup.
- **External inputs:** \`WAIT_CYCLES\` and \`AVG_CYCLES\`.

### v1.1.0 averaging method

1. Detect a new sweep point using \`PNUM\`.
2. Reset the cycle accumulators at the new point.
3. Ignore the first \`WAIT_CYCLES\` complete cycles.
4. Accumulate every sample in the next \`AVG_CYCLES\` complete cycles.
5. Divide the accumulated four-channel sums by the total number of samples.
6. Emit one \`Valid\` pulse when the requested complete-cycle average is ready.

This is **complete-cycle batch averaging**, not the sample-by-sample circular moving average used in v1.0.0. It does not retain a history buffer and does not use \`NMAX\`.

## Previous version

- [v1.0.0/Average_Mean_Cycle.m](v1_0_0/Average_Mean_Cycle.m): sample-by-sample moving average with a fixed circular buffer. This version is retained for comparison and rollback.

## Important integration notes

- \`Phase\` must be a continuously accumulated cycle count, with increment \`Freq*Ts\` each base sample. It must not reset at every phase wrap.
- Keep \`WAIT_CYCLES + AVG_CYCLES\` within the dwell cycles of each sweep point. With the current 8-cycle dwell, the suggested initial test values are \`WAIT_CYCLES = 1\` and \`AVG_CYCLES = 2\` or \`5\`, provided their sum does not exceed the dwell.
- \`Valid\` is a one-base-sample pulse (width \`Ts\`). If a downstream logging block samples at \`3*Ts\`, the pulse can be missed depending on sample-hit alignment. Use a base-rate capture or a properly designed pulse-stretch/handshake stage if needed.
- The v1.1.0 code has not yet been compiled or run in the user's Simulink model. Verify the average values, Valid timing, and one-record-per-PNUM behavior before treating it as stable.
- Because v1.1.0 accumulates complete cycles and emits Valid at the cycle boundary after the requested average is complete, its output and trigger timing may differ slightly from v1.0.0. Compare both versions in the same test conditions.

## Version history

See [CHANGELOG.md](CHANGELOG.md).
