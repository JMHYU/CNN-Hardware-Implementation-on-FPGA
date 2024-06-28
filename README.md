# CNN-Hardware-Implementation-on-FPGA
Implemented hardware for CNN operations on a DE1-SoC board, addressing FPGA resource  limitations by designing pipelined CNN cores. Developed memory access mechanism using on-chip SRAM blocks for communication between FPGA  and HPS.
<br/> <br/>

## Acknowledgements
I would like to express my deepest gratitude to Professor Ki-Seok Chung, TA Youngwon Yoo, and TA Minho Choi for their invaluable guidance and support throughout the coursework (2024 SoC Design in Hanyang University) lab sessions. They organized the whole structure of this project and gave us insightful feedback which greatly contributed to the successful completion of this project.
<br/> <br/>

## This repository
DE1_SoC_Computer_Unpipelined: This was the original design: we aimed to create fast hardware capable of computing an entire convolutional layer (kernel striding the input feature map -> accumulation) in about 4-5 cycles. However, due to the resource limitations of the DE1-SoC board (with only 87 DSP blocks), we had to pipeline this process for proper operation.

DE1_SoC_Computer/verilog
