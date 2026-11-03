# MATLAB-Research

MATLAB Research Codes for Power Electronics

## Impedance sweep

Versioned MATLAB Function code for impedance-sweep measurement is stored in [Impedance_Sweep/](Impedance_Sweep/).

- Current candidate: [Average_Mean_Cycle v1.2.0](Impedance_Sweep/v1_2_0/Average_Mean_Cycle.m)
- v1.2.0 usage notes: [Impedance_Sweep/v1_2_0/README.md](Impedance_Sweep/v1_2_0/README.md)
- Previous complete-cycle batch version: [Average_Mean_Cycle v1.1.0](Impedance_Sweep/v1_1_0/Average_Mean_Cycle.m)
- Earlier sample-by-sample moving-average version: [Average_Mean_Cycle v1.0.0](Impedance_Sweep/v1_0_0/Average_Mean_Cycle.m)
- Change history and known issues: [Impedance_Sweep/CHANGELOG.md](Impedance_Sweep/CHANGELOG.md)
- Integration guide: [Impedance_Sweep/README.md](Impedance_Sweep/README.md)

Version 1.2.0 accumulates cycle phase internally from `Freq*Ts`, removes the external `Phase` input, and locks measurement after one `Valid` pulse per `PNUM`. Its target configuration is `Ts=8e-8 s` with perturbation frequencies up to 2 kHz. It is a candidate pending Simulink compile and runtime verification; earlier versions are retained separately.
