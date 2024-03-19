# Virtuoso Verfication Workflow

在Innovus完成所有的Place & Route并修复基本上所有的DRC之后，使用Virtuoso：
* 修复剩余或新增的DRC
* 检查LVS

## 将设计导入Virtuoso

* 在Innovus流程中，通过如下的命令导出GDS文件和门级网表
    ```tcl
    streamOut -mapFile ${rm_lef_layer_map} ../data/${rm_core_top}.gds2 -mode ALL \
            -merge "/work/home/wumeng/pdks/tsmc/tsmc22ull/tcbn22ullbwp7t30p140lvt_110a/digital/Back_End/gds/tcbn22ullbwp7t30p140lvt_110a/tcbn22ullbwp7t30p140lvt.gds" 

    saveNetlist ../data/${rm_core_top}.pg.flat.v -flat -phys -excludeLeafCell -excludeCellInst $lvs_exclude_cells
    ```

* 新建一个存放Virtuoso工程文件的文件夹，在其中`b virtuoso`打开Virtuoso
* 打开Library Manager，确保设计所需要的工艺库(例如`tsmcN22`)在Virtuoso搜索路径中
* 使用Library Manager新建一个Library用于存放完成后端流程的设计
* 选择`Attach to an existing technology library`，并选择相应的工艺库。
* 在Virtuoso窗口上方选择`File`->`Import`->`XStream`
* 在Innovus的输出文件夹中添加`<MY_MODULE>.gds2`文件，添加到此前新建的Library中，并选择所从属的工艺库，按下方`Translate`按钮导入设计
* 在Virtuoso窗口上方选择`File`->`Open`打开顶层模块的Layout

* **最小格点设置**：在Layout Suite L上方选择`Options`->`Display`，把`X Snap Spacing`和`Y Snap Spacing`改成0.005

## 检查LVS

* 将门级网表转换成`.cdl`格式
* 需要在`v2lvs.run`文件中添加相应工艺库的SPICE文件
    ```bash
    cd ../cadence
    b ./v2lvs.run
    ```

* 导入LVS Runset文件
    * 在Virtuoso窗口上方选择`Calibre`->`nmLVS`
    * 在`Runset File Path`中添加Calibre文件
* 在左侧`Inputs`->`Netlist`中选择导入`.cdl`格式的SPICE文件
* 在左侧`LVS Options`->`Supply`中定义Power nets与Ground nets
* 如有需要，在左侧各个选择中设置相应的选项
* 在上方`File`->`Save Runset As`保存LVS的配置，以便后续使用
