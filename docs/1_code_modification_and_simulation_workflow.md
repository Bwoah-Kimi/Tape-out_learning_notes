# 面向流片的XiangShan配置与仿真

[XiangShan](https://xiangshan-doc.readthedocs.io/zh-cn/latest/)是一个规模很大，版本迭代很快的开源项目。截止2024年3月已经迭代至第三个版本（昆明湖），香山团队已经完成了两次流片。

为了在自己的流片工作中使用香山处理器，需要做不少的调整，在此做一些简要的介绍。

总体上来说，在进入完整的数字综合+后端流程之前，大致有几个准备步骤。

* **熟悉工程环境**：了解香山大致的代码结构，Chisel -> Verilog的编译过程以及参数配置。
* **调整参数配置**：香山处理器用Chisel语言编写，调整一些简单的参数选项就可以改变CPU的微架构，例如发射宽度、取指宽度、缓存大小等等。因为后续流片不可能使用完整的香山核，因此需要适当缩小部分参数。

另外，我们的流片工作肯定不是直接照搬香山CPU，肯定会在这之上做一些调整或修改，例如指令集扩展、功耗或时钟的优化，等等。根据所需的功能，可以考虑直接修改Chisel代码，或者编译成Verilog之后再做调整。
* **搭建仿真环境**：在修改设计的各个节点，我们都应该用仿真程序验证设计的正确性。可以使用香山自带的仿真环境进行验证，但是默认的仿真设置调用`NEMU`指令模拟器进行Difftest，若我们调整了CPU的代码功能，就需要去除Difftest选项。另外，为了后续的FPGA验证以及流片后测试，我们也需要搭建自己的仿真以及测试环境。

## 工程环境配置

* 香山环境配置较为复杂，需要用到`verilator`、`riscv-toolchain`等多个工具以及大量的依赖包。
* 参考<https://xiangshan-doc.readthedocs.io/zh-cn/latest/tools/xsenv/>中的介绍进行操作。
* 需要注意`XiangShan`和`NEMU`项目的版本。
* 为了成功将Chisel编译成Verilog代码，需要在`build.sc`中修改内存限制，详见<https://github.com/OpenXiangShan/XiangShan/issues/891>
    ```
    override def forkArgs = Seq("-Xmx15G", "-Xss256m")
    ```	

## 修改Cache大小

因为学术流片的限制以及用途，我们不需要实现完整的香山核，可以适当减小一些参数配置，以减小版图面积以及实现的难易程度。

香山团队在 `./src/main/scala/top/Config.scala`中提供了一些参数配置选项。可以参考`MinimalConfig`进行其他自定义的配置。

在生成Verilog代码/仿真时可以添加选项`CONFIG=MyConfig`来指定选择的配置，具体详见<https://xiangshan-doc.readthedocs.io/zh-cn/latest/misc/config/>

由于`MinimalConfig`中的缓存大小对于流片来讲太大，我们需要去除缓存/减小缓存的大小
* dcache (32KB) 相关参数配置在`./src/main/scala/xiangshan/cache/dcache/DCacheWrapper.scala`
```
nSets: Int = 32, 
nWays: Int = 4,
rowBits: Int = 64,
```
* icache(8KB) 相关参数配置在`./src/main/scala/xiangshan/frontend/icache/ICache.scala`
```
nSets: Int = 32,
nWays: Int = 4,
rowBits: Int = 64,
```
* 将dcache与icache均从`nSets = 64`修改为：`nSets = 32`
* 修改`MinimalConfig`中`nSets`的参数大小，使得L3大小减小至64KB，L2的大小减小至64KB。

## 修改香山代码

此处根据自己的研究目标适当修改香山代码，不再赘述。应当阶段性进行仿真验证，确保设计正确性。

## 生成Verilog代码

* `make verilog`生成**可综合的单核代码**
    * 输出的文件在`XiangShan/build/XSTop.v`
    * 去除了Difftest等仿真用的调试模块
* `make sim-verilog`生成用于仿真的Verilog文件，若后续使用vcs仿真，可使用`make simv`
* `make emu`用于生成Verilator仿真程序

### 加速Chisel -> Verilog编译速度

* 参考<https://xiangshan-doc.readthedocs.io/zh-cn/latest/tools/compile-and-sim/>
* 使用CIRCT代替默认的Scala Firrtl Compiler编译香山
	* 在本地从源码编译CIRCT，**需要将编译选项中DEBUG更换成Release**
	* 将circt/bin路径添加到PATH环境变量中
	* 在make命令时加上`MFC=1`
* 指定编译时的核数，`-jN`，其中N为核数

## 为流片调整Verilog代码

### 分板块进行数字流程

由Chisel生成的Verilog代码在`XSTop.v`，没有任何的可读性可言。
万幸的是，香山团队在`./scripts`提供了几个脚本，运行`generate_all.sh`将Verilog代码分成几个板块（例如L3 Cache、执行单元），并且将每个Verilog模块分成单独的文件。
在进行综合、后端等数字流程时，分成几个模块进行更为合理。若一个设计的规模过大、复杂性太高，很难得到较好的效果。

### 替换SRAM、Register File

生成的Verilog代码中，有几十个`array_xxx_ext.v`文件，被用于DCache、ICache等寄存器堆和高速缓存。
这些阵列需要用`SRAM Compiler`、`Register File Compiler`替换成专门的IP核，能够显著减小设计的面积。

## 初步仿真验证

### 使用Verilator

* 使用香山自带的开发环境，可以用Verilator初步验证设计是否正确。

* `./build/emu -i WORKLOAD_BIN.bin`

### 使用VCS

* 参考<https://xiangshan-doc.readthedocs.io/zh-cn/latest/tools/vcs/>
* `make simv CONFIG=MyConfig Release=1`可以生成用于仿真的`SimTop.v`，由于本地系统无法运行VCS，使用该make命令无法生成simv可执行文件。
* 使用重定向输出保存`vcs`命令，在支持VCS的环境中重新运行该命令，从而生成`simv`可执行文件。
* 运行`simv`，并指定负载程序
* 使用Verdi或其他程序查看波形，检查正确性

## 流片环境仿真验证

香山自带的仿真程序中调用了大量的C函数，例如`SimJTag`，`SimMMIO`等无法综合的模块。
在为FPGA验证以及流片准备的版本中，需要**将所有不可综合、调用C代码的函数去除**，剩下可综合的裸核，以及测试所需的必要模块。

需要注意的是，香山团队在默认的设置选项中保留了一部分基本的Difftest模块，需要在`Parameters.scala`中去除相应的选项。

通过`grep -rn "DPI-C"`可以查看代码中是否有调用C函数。

### 部分基础概念介绍

搭建自己的仿真验证环境涉及到一些软硬件概念，在此简单介绍。

* DMA
    * Direct Memory Access (DMA)，直接内存访问，是一种在计算机系统中，允许某些硬件子系统在主内存和设备之间直接传输数据，而无需通过CPU进行中转的技术
* MMIO
    * MMIO全称为Memory Mapped I/O（内存映射输入/输出），是一种在计算机系统中，允许CPU使用**内存访问指令**（如LOAD和STORE）来访问设备的方法。
    * 在这种方法中，设备的寄存器被映射到系统的地址空间中，就像普通的内存单元一样。
    * 当CPU向这些特殊的内存地址写入数据时，它实际上是向设备的寄存器写入数据；当CPU从这些地址读取数据时，它实际上是从设备的寄存器读取数据。这种方式使得CPU可以使用相同的指令集来访问内存和设备，从而简化了硬件和软件的设计。

### 接口介绍

`XSTop.v`是经过编译之后的处理器Verilog代码，即可综合的裸核。处理器核对外暴露出了几套接口，在此记录。
* dma：一套AXI接口，没有使用
    ```scala
    l_soc.module.dma <> 0.U.asTypeOf(l_soc.module.dma)
    ```
* peripheral：一套AXI接口，CPU为Master，Peripheral为Slave
    ```scala
    val l_simMMIO = LazyModule(new SimMMIO(l_soc.misc.peripheralNode.in.head._2))
    val simMMIO = Module(l_simMMIO.module)
    l_simMMIO.io_axi4 <> soc.peripheral
    ```
    
    SoC的Peripheral模块在SimTop中通过AXI4连接到SimMMIO中
    * auto_out_3: intrGen
    * auto_out_2: SD
    * auto_out_1: FLASH (boot address: 0x1000_0000)
    * auto_out_0: UART

    **XSTop在reset结束之后会从0x1000_0000位置读取指令，最终跳转到主存上执行程序。**
* memory：一套AXI接口，CPU为Master，Memory为Slave。Memory模块在SoC模块中通过AXI4接口连接到核上
    ```scala
    val simAXIMem = Module(l_simAXIMem.module)
    l_simAXIMem.io_axi4 <> soc.memory
    ```

`SimTop.v`是使用香山仿真环境所生成的SoC Verilog代码。为替换成自己的仿真验证环境，我们需要在此基础上进行修改。

`SimTop.v`对外暴露的接口如下所示：
```scala
  val io = IO(new Bundle() {
    val logCtrl = new LogCtrlIO
    val perfInfo = new PerfInfoIO
    val uart = new UARTIO
  })
```
```verilog
module SimTop(
  input         clock,
  input         reset,
  input  [63:0] io_logCtrl_log_begin,
  input  [63:0] io_logCtrl_log_end,
  input  [63:0] io_logCtrl_log_level,
  input         io_perfInfo_clean,
  input         io_perfInfo_dump,
  output        io_uart_out_valid,
  output [7:0]  io_uart_out_ch,
  output        io_uart_in_valid,
  input  [7:0]  io_uart_in_ch
);
```

在可综合的`XSTop.v`的基础上，我们通过核暴露出来的两套AXI接口，分别接到BootROM和主存Memory上。

BootROM核Memory上的内容需要自行配置。

另外，我们把核暴露出来的JTAG接口连到SoC模块的IO上，用于后续FPGA调试。

### VCS仿真验证

在使用FPGA上板验证之前，使用可调试性更强、仿真速度更快的的VCS进行行为级仿真验证，确保BootRom和Memory可以正常使用。

### Verdi查看波形