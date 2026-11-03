# MATLAB-Research

MATLAB Research Codes for Power Electronics

## Impedance sweep

Versioned MATLAB Function code for impedance-sweep measurement is stored in [Impedance_Sweep/](Impedance_Sweep/).

- **Final user-designated version:** [Average_Mean_Cycle v1.3.0](Impedance_Sweep/v1_3_0/Average_Mean_Cycle.m)
- v1.3.0 usage notes: [Impedance_Sweep/v1_3_0/README.md](Impedance_Sweep/v1_3_0/README.md)
- Previous version: [Average_Mean_Cycle v1.2.0](Impedance_Sweep/v1_2_0/Average_Mean_Cycle.m)
- Earlier complete-cycle batch version: [Average_Mean_Cycle v1.1.0](Impedance_Sweep/v1_1_0/Average_Mean_Cycle.m)
- Original sample-by-sample moving-average version: [Average_Mean_Cycle v1.0.0](Impedance_Sweep/v1_0_0/Average_Mean_Cycle.m)
- Change history and verification notes: [Impedance_Sweep/CHANGELOG.md](Impedance_Sweep/CHANGELOG.md)
- Integration guide: [Impedance_Sweep/README.md](Impedance_Sweep/README.md)

Version 1.3.0 is the user-designated final/recommended source for the current 1 Hz–100 kHz impedance-sweep workflow. It accumulates cycle phase internally from `Freq*Ts`, uses `PNUM` to reset for each new sweep point, accepts external `WAIT_CYCLES` and `AVG_CYCLES`, and emits one base-execution-step `Valid` pulse per sweep point. The extra 0.1-cycle dwell margin is handled by the external sweep counter and is not included in the average. The target configuration is `Ts=8e-8 s`. Earlier versions are retained separately. The GitHub backup does not itself imply that the target Simulink model has been compiled or runtime-tested.
