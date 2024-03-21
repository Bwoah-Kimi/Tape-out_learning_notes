# Virtuoso Verfication Workflow

在Innovus完成所有的Place & Route并修复基本上所有的DRC之后，使用Virtuoso：
* 修复剩余或新增的DRC
* 检查LVS

## 将设计导入Virtuoso

* 在Innovus流程中，通过如下的命令导出GDS文件和门级网表。
    * 如果设计中使用了SRAM/Register File或子模块，需要在`-merge`选项中把Macro的`gds`或`gds2`文件路径添加进来。
    ```tcl
    streamOut -mapFile ${rm_lef_layer_map} ../data/${rm_core_top}.gds2 -mode ALL \
            -merge "/work/home/wumeng/pdks/tsmc/tsmc22ull/tcbn22ullbwp7t30p140lvt_110a/digital/Back_End/gds/tcbn22ullbwp7t30p140lvt_110a/tcbn22ullbwp7t30p140lvt.gds \
            /path/to/my/sram/gds \
            /path/to/my/register_file/gds \
            /path/to/my/macro/gds" 

    saveNetlist ../data/${rm_core_top}.pg.flat.v -flat -phys -excludeLeafCell -excludeCellInst $lvs_exclude_cells
    ```

* 新建一个存放Virtuoso工程文件的文件夹，在其中`b virtuoso`打开Virtuoso
* 打开Library Manager，确保设计所需要的工艺库(例如`tsmcN22`)在Virtuoso搜索路径中
* 使用Library Manager新建一个Library用于存放完成后端流程的设计
* 选择`Attach to an existing technology library`，并选择相应的工艺库(例如`tsmcN22`)。
* 在Virtuoso窗口上方选择`File`->`Import`->`Stream`
* 在Innovus的输出文件夹中添加`<MY_MODULE>.gds2`文件，添加到此前新建的Library中，并选择所从属的工艺库，按下方`Translate`按钮导入设计
* 在Virtuoso窗口上方选择`File`->`Open`打开顶层模块的Layout

* **最小格点设置**：为了在Virtuoso中正常选中器件，进行各种操作，需要在Layout Suite L上方选择`Options`->`Display`，把`X Snap Spacing`和`Y Snap Spacing`改成0.005

## 检查LVS

* LVS全称是Layout Versus Schematic，翻译为版图与原理图一致性检查。
* LVS检查的是目前的版图与门级网表所代表的逻辑是否一致。如果是一致的，那么说明物理版图与电路原理图一致，也就是Innovus的后端流程无误。
* 将门级网表`.v`转换成`.cdl`格式
    * 需要在`./cadence/v2lvs.run`文件中添加相应工艺库的SPICE文件，随后运行如下指令
    ```bash
    cd ./cadence
    b ./v2lvs.run
    ```

* 导入LVS Runset文件
    * 在Virtuoso窗口上方选择`Calibre`->`nmLVS`
    * 在`Runset File Path`中添加Calibre文件
* 在左侧`Inputs`->`Netlist`中选择导入`.cdl`格式的SPICE文件
* 在左侧`LVS Options`->`Supply`中定义Power nets与Ground nets
* 如有需要，在左侧各个选择中设置相应的选项
* 在上方`File`->`Save Runset As`保存LVS的配置，以便后续使用

## 检查DRC

* DRC全称为Design Rule Check，检查的是目前的版图中各个器件、布局布线的摆放、间距、密度等指标是否满足晶圆厂的规范。
* 理想情况下，我们不需要在Virtuoso中修改DRC报错，我们希望能够使用Innovus提供的工具自动修DRC 相关内容详见[innovus_backend_workflow.md](./4_innovus_backend_workflow.md)中的相关内容。
