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

 As a student who is truely interested in AI and FPGA, I started this project to study AI accelerator in basic level. Thanks to [matbi youtube](https://www.youtube.com/@verilog), I could make this project. I highly recommend you this chanel if you are interested in FPGA.



## how it works

<img src="/img/block_diagram.png" width="450px" height="300px" alt="BlockDiagram"></img><br/>

