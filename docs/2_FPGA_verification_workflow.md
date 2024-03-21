# FPGA验证

使用Xilinx Vivado 2019.1进行FPGA验证

## FPGA流程简介

在完成RTL代码设计之后，可以进入FPGA验证流程，大致分为以下几个阶段：

### 导入设计

打开Vivado，选择`Create Project`，选择合适的工程名字和路径。如果是在本地运行，尽量避免中文路径，否则Vivado后续可能报错。

选择`RTL Project`，连续选择`Next`，在`Default Part`选择验证所使用的FPGA核心板型号

完成工程创建向导之后即可进入Vivado主界面。在`PROJECT MANAGER` -> `Sources`添加RTL代码
![add_sources](./figs/vivado_sources.png)

在弹出界面中选择`Add or create design sources` -> `Add Files`即可导入设计。

### 编写仿真程序

为了验证RTL代码是否正确，需要用Verilog或SystemVerilog编写一个Testbench，通过观察波形验证设计是否符合需求。

一个简单的Testbench大致如下。
```verilog

```

### Behavioral Simulation 行为仿真

对RTL代码编译之后即可进行的仿真，用于验证逻辑功能的正确性。在逻辑综合需要进行功能仿真，以便尽早发现设计中的缺陷。

### Synthesis 逻辑综合

### Implementation Place & Route实现

### Generate Bitstream