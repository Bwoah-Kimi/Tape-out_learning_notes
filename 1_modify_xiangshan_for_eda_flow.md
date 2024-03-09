# 面向流片的XiangShan配置与使用

XiangShan是一个规模很大，版本迭代很快的开源项目。截止2024年3月已经迭代至第三个版本（昆明湖），香山团队已经完成了两次流片。

为了在自己的流片工作中使用香山处理器，需要做不少的调整，在此做一些简要的介绍

## 环境配置

* 香山环境配置较为复杂，需要用到`verilator`、`riscv-toolchain`等多个工具以及大量的依赖包。
* 参考<https://xiangshan-doc.readthedocs.io/zh-cn/latest/tools/xsenv/>中的介绍进行操作。
* 需要注意`XiangShan`和`NEMU`项目的版本。
* 为了成功将Chisel编译成Verilog代码，需要在`build.sc`中修改内存限制，详见<https://github.com/OpenXiangShan/XiangShan/issues/891>
    ```
    override def forkArgs = Seq("-Xmx15G", "-Xss256m")
    ```	

## 修改Cache大小

* `./src/main/scala/top/Config.scala`中是香山的参数配置文件
* 在生成Verilog/仿真时可以添加选项`CONFIG=MyConfig`来指定选择的配置，具体详见<https://xiangshan-doc.readthedocs.io/zh-cn/latest/misc/config/>>
* 由于`MinimalConfig`中的缓存大小对于流片来讲太大，我们需要去除缓存/减小缓存的大小
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
为此，这些模块以及调用这些模块的上层模块，需要添加_VSS, VDD_的IO定义与连接。`add_power_pins.py`能够基本实现这个功能，**但是脚本鲁棒性不好，修改完代码后需要double check！**

## 仿真验证

### 使用Verilator

* `./build/emu -i WORKLOAD_BIN.bin`即可运行Verilator仿真程序，验证设计是否正确

### 使用VCS

* 参考<https://xiangshan-doc.readthedocs.io/zh-cn/latest/tools/vcs/>
* `make simv CONFIG=MyConfig Release=1`可以生成用于仿真的`SimTop.v`，由于本地系统无法运行VCS，使用该make命令无法生成simv可执行文件。
* 使用重定向输出保存`vcs`命令，在支持VCS的环境中重新运行该命令，从而生成`simv`可执行文件。
* 运行`simv`，并指定负载程序
