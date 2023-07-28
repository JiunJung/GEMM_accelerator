# GEMM accelerator

- Hardware accelerator for AI calculation.
- IP(Verilog code) for GEMM.    
- It can get up to 4096 input nodes and outputs 4 output nodes.
- It uses AXI4-LITE.

[GEMM(General matrix multiply)](https://en.wikipedia.org/wiki/GEMM, "wikipedia GEMM") is one of the big bottlenecks in AI calculation. You can use GPU for this calculation. But still, GPU is too expensive and not very optimized for AI. (Also it costs so much electric power)

AI accelerator helps users to get AI calculation results with low cost and power. This fully connected layer can accelerate fully connected layer calculation with parallelized 4 GEMM core.

It can be synthesised in VIVADO 2023.1 and you can upload the bitstream on [ZYBO-Z720](https://digilent.com/reference/programmable-logic/zybo-z7/start, "to buy zybo z7 20")

<br/>

## about the project

 As a student who is truely interested in AI and FPGA, I started this project to study AI accelerator in basic level. Thanks to [matbi](https://semisgdh.com/), I could build this project. I simply changed some lines in his code. The code is private for his paid lecture. you can get synthesisable verilog code and some great idea in his lecture. (matbi youtube : https://www.youtube.com/c/aifpga)



## how it works

