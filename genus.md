# Genus Workflow

## RTL数字综合

1. 修改工艺路径
  * `./scripts/design_input_macro.tcl` 中修改PDK和标准库的路径
    ```tcl
    set std_lib MY_STD_LIB
    ```
  * `std_lib`可选：
   * `tcbn22ullbwp30p140lvt`
   * `tcbn22ullbwp30p140hvt`
   * `tcbn22ullbwp7t30p140lvt`
   * `tcbn22ullbwp7t30p140hvt`
   * `tcbn22ullbwp7t40p140ehvt`
   * `tcbn22ullbwp7t40p140hvt`

2. 添加RTL
  * 添加RTL代码至`./rtl/`
  * 在`./rtl/srcs.tcl`中添加文件名
    ```tcl
    read_hdl ../rtl/MY_MODULE_1.v
    read_hdl ../rtl/MY_MODULE_2.v
    ```

3. 定义顶层模块
  * 在`./scripts/core_config.tcl`中定义需要综合的**顶层模块名称**
   ```tcl
   set rm_core_top MY_TOP_MODULE
   ```

4. 定义时钟周期
  * 在`./scripts/design_input_macro.tcl`中
    ```tcl
    set rm_clock_period MY_CLOCK_PERIOD
    ```
  * 单位为ns

5. 带有SRAM的数字综合
  * 将所需要的SRAM lib文件生成并放置于`./sram/my_sram_lib_files/`文件夹中，
  * 在`./scripts/design_input_macro.tcl`中添加综合所需要的sram
    ```tcl
    set sram_insts [concat $MACROname_rams \
        "my_sram_lib_files" \
    ]
    ```

6. 启动综合
  * `b make genus_syn`

7. 检查生成文件
  * `./data/MY_TOP_MODULE-genus.v`：生成的gate level netlist
  * `./data/func-genus.sdc`：生成的SDC
  * `./logs/genus_synthesis.log`：生成的log文件
  * `./reports/genus/func_tt_0p90v_025c_timing.rpt`：tt corner的timing report

## Gate-level的数字仿真

* 进行带有SDF的仿真，确保生成的gate level netlist逻辑正确
* **需要在testbench中将SDF文件annotate**
  ```verilog
  initial begin
  $sdf_annotate("../models/sdf/adder_8bit.sdf", ADDER,,, "MAXIMUM", "1.6:1.4:1.2", "FROM_MTM");
  ```
* `b make compile_gate`
* `b make verdi` 打开波形图
