# MATLAB-Research

MATLAB Research Codes for Power Electronics

## Impedance sweep

Versioned MATLAB Function code for impedance-sweep measurement is stored in [Impedance_Sweep/](Impedance_Sweep/).

- Current candidate: [Average_Mean_Cycle v1.1.0](Impedance_Sweep/v1_1_0/Average_Mean_Cycle.m)
- Previous sample-by-sample moving-average version: [Average_Mean_Cycle v1.0.0](Impedance_Sweep/v1_0_0/Average_Mean_Cycle.m)
- Change history and known issues: [Impedance_Sweep/CHANGELOG.md](Impedance_Sweep/CHANGELOG.md)
- Usage notes and integration cautions: [Impedance_Sweep/README.md](Impedance_Sweep/README.md)

Version 1.1.0 removes the large sample-history buffer and uses complete-cycle batch accumulation. It is a candidate version pending Simulink compile and runtime verification. Prior versions are retained separately.
