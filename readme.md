# GEMM accelerator

- Hardware accelerator for AI calculation.
- IP(Verilog code) for GEMM.    
- It can get up to 4096 input nodes and outputs 4 output nodes.
- It uses AXI4-LITE.

[GEMM(General matrix multiply)](https://en.wikipedia.org/wiki/GEMM, "wikipedia GEMM") is one of the big bottlenecks in AI calculation. You can use GPU for this calculation. But still, GPU is too expensive and not very optimized for AI. (Also it costs so much electric power)

AI accelerator helps users to get AI calculation results with low cost and power. This fully connected layer can accelerate fully connected layer calculation with parallelized 4 GEMM core.

It can be synthesised in VIVADO 2023.1 and you can upload the bitstream on [ZYBO-Z720](https://digilent.com/reference/programmable-logic/zybo-z7/start, "to buy zybo z7 20")

<br/>

## About the project

 As a student who is truely interested in AI and FPGA, I started this project to study AI accelerator in basic level. Thanks to [matbi youtube](https://www.youtube.com/@verilog), I could make this project. I highly recommend you this chanel if you are interested in FPGA.



## How it works

<img src="/img/block_diagram.png" width="450px" height="300px" alt="BlockDiagram"></img><br/>

<img src="/img/RegisterMap.png" width ="300px" height="450px" alt="registerMap"></img><br/>

GEMM Accelerator IP is connected with processing system which has ARM Cortex A9. Using registers in 'myip_v1_0_S00_AXI' which is a controller in AXI interface, you can control the GEMM core to run and you can put data into brams.

GEMM core gets inputs and weights from Bram0 and Bram1. And It runs as FSM. During runtime, GEMM core uses 4 core of multiplication and it outputs 4 output nodes simultaneously. (If you want more output nodes, you can simply add more mul core. Or you can just repeat the process.)

Input, weight data should be 0~255. In 32bit register, four 8bit data will saved. And the four data is for four output nodes.

<img src="/img/DataSplit.png" width ="300px" height="30px" alt="DataFormat"></img><br/>

## How to use

 Using Vivado 2023.1, upload the HW file as design file. And make it as a IP.

 After making the IP, you can make a project with connecting the IP with zynq processing system. and make the bitstream file of the project.

<img src="/img/project.png" width ="500px" height="300px" alt="DataFormat"></img><br/>

<img src="/img/fpga.png" width ="300px" height="300px" alt="DataFormat"></img><br/>

 Make XSA file from your bitstream file to start Vitis.

 Using Vitis, upload the 'main.c' file. After building main.c file, you can upload it into FPGA with the bitstream of GEMM IP. And you can enter your inputs and weights. Then, you can get your 4 nodes of output data.

<img src="/img/result.png" width ="300px" height="400px" alt="result"></img><br/>



