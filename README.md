# CNN-Hardware-Implementation-on-FPGA
Implemented hardware for CNN operations on a DE1-SoC board, addressing FPGA resource  limitations by designing pipelined CNN cores. Developed memory access mechanism using on-chip SRAM blocks for communication between FPGA  and HPS.
<br/> <br/>

## Acknowledgements
I would like to express my deepest gratitude to Professor Ki-Seok Chung, TA Youngwon Yoo, and TA Minho Choi for their invaluable guidance and support throughout the coursework (2024 SoC Design in Hanyang University) lab sessions. They organized the whole structure of this project and gave us insightful feedback which greatly contributed to the successful completion of this project.
<br/> <br/>

## This repository
- DE1_SoC_Computer_Unpipelined: This was the original design. We aimed to create fast hardware capable of computing an entire convolutional layer (kernel striding the input feature map -> accumulation) in about 4-5 cycles. However, due to the resource limitations of the DE1-SoC board (with only 87 DSP blocks), we had to pipeline this process for proper operation.

- DE1_SoC_Computer/verilog: The only difference between DE1_SoC_Computer_Unpipelined and this version is in cnn_acc_ci.v and cnn_kernel.v. Now, we use an FSM to handle the striding process (kernel striding the input feature map from the top left to the bottom right). Each state parses a different set of input feature maps, multiplies them with the kernel, and accumulates the results.
<br/> <br/>
## Architecture
![Architecture](https://github.com/JMHYU/CNN-Hardware-Implementation-on-FPGA/assets/165994759/c9bf6248-0edb-4a3a-8679-04a7f23d614e)

1. Software (C code) runs on the HPS (Hard Processor System).
2. When the C code starts, the HPS writes a 1 to the least significant bit (LSB) of ON-CHIP SRAM 0, which serves as a handshake bit.
3. The FPGA continuously checks this handshake bit to see if it is set to 1 during the polling state (mat_ops_controller.v).
4. If the handshake bit is set to 1, then mat_ops_controller switches its state to START -> OPS -> DONE.
5. When the convolution operation is completed, the FPGA writes a 0 to the handshake bit.
6. The HPS then checks the handshake bit and prints the results from SRAM1 and SRAM2.

<br/> <br/>
## Result
We can see that the Hardware performance is still better than that of SW even if we pipeline the MAC processes.
![Putty_results](https://github.com/JMHYU/CNN-Hardware-Implementation-on-FPGA/assets/165994759/d9a675a0-f5b2-4ddc-82a6-3def3fc167a8)
<br/>

Even the pipelined version utilizes all the available DSP(floating point number multiplication) blocks.
![Total_DSP_Blocks](https://github.com/JMHYU/CNN-Hardware-Implementation-on-FPGA/assets/165994759/25f4216d-6471-48be-a350-30ed987535d3)
![Total LABs](https://github.com/JMHYU/CNN-Hardware-Implementation-on-FPGA/assets/165994759/a0304fba-b839-42c0-bfeb-2ada412b7e11)
![M10k blocks](https://github.com/JMHYU/CNN-Hardware-Implementation-on-FPGA/assets/165994759/771c9026-2195-4d14-9245-5bcab022a5eb)
