# Innovus learning notes

* 此处大致介绍了Innovus后端流程，为带有SRAM/Register File的后端流程。
* 运行Innovus后端需要在Genus synthesis完成的基础上进行。
* 脚本中许多的参数设置，例如width, spacing，以及MACRO的位置摆放需要根据版图大小以及布线情况来设定，需多次迭代优化。

## 部分命令说明

* 在讲述具体的后端流程之前，有必要对一些命令进行说明，或许会对后端流程debugging有一定帮助
* 在运行过程中，如果碰到报错，或者对于某些命令参数选项不确定，可以在Innovus命令行中输入`man <CMD_Name>`来查看官方Manual以获得相应信息。
* 个人感觉，Manual对于命令的说明较为清晰，配合ChatGPT可以获得较好的效果，而对于报错信息，官方手册以及网络信息都比较欠缺，需更有针对性进行查找。

### 关于`setMultiCpuUsage`命令

* 若使用`setMultiCpuUsage -localCpu max -cpuAutoAdjust true -verbose`，可能会导致Innovus闪退。大致原因是CPU核数过多，导致服务器终止进程。
* 建议使用`setMultiCpuUsage -localCpu 32`，可以保证Innovus稳定运行。

### 关于`createRouteBlk`命令

* Description: creates a routing blockage object. The object area prevents routing of specified metal layers, signal routes and hierarchical instances in this area.
* 对于顶层模块集成的后端流程，需要考虑使用该命令
* SRAM/Register File的LEF文件中定义了哪些Layer被占用，无需另外使用`createRouteBlk`在SRAM/Register File周围设置Routing Blockage
* 顶层模块集成时，可以考虑减小Routing Blockage的`-spacing`选项，供`ecoRoute`有更多空间布线以修复DRC
* `-pgnetonly`
	* Specifies that the routing blockage is to be **applied only on power or ground net** special routes and not on signal nets.
 	* This option affects only commands that create special routes, such as `addRing`, `addStripe`, or `sroute`, when they are used for PG nets.
	* `NanoRoute`, which is used to connect tie-high or tie-low connections or to connect to secondary standard-cell power-pin connections, is also not affected by this option.
  * Use this option during power planning to prevent power routes from getting too close to block edges and, as a result, blocking signal pin access or causing congestion in narrow channels.
* `-exceptpgnet`
	* Specifies that the routing blockage is to be **applied on a signal net routing** and not on power or ground net routing.
	* Use this option to block signal routing above or around a sensitive block to avoid noise from nearby signal nets but still allow power connections to go through the blockage.
	* Blocking the signal net routing helps in avoiding cross talk or coupling caused by signal routes.

### 关于`editPin`命令

* 对于大部分的数字模块，管脚数量是成百上千的，无法手动写命令设置每一个管脚。
* 在Innovus GUI界面中上方工具栏选择`Edit -> Pin Editor`根据需求添加管脚。
* 在`innovus.cmd`文件中可以看到每一步操作对应的命令，其中就有我们所需要的`editPin`命令。
* 由于奇数层为横向金属，偶数层为纵向金属，因此对于Top/Bottom可以选择M4/M6等金属，Left/Right可以选择M3/M5等金属。
* **注意**：
	* 模块的P/G不需要在这一步设置管脚。在布局布线完成之后，将会使用`createPGPin`生成专门的P/G管脚。
	* 查看命令是否有多余的选项，例如`-USE GROUND`，可能会导致后续步骤（例如CTS）无法进行

### 关于`addEndCap`命令

* In digital IC design, especially with automated P&R tools, the standard cells are organized in rows throughout the silicon area.
* These standard cells are the building blocks of the design, containing logic gates, flip-flops, and other digital circutry.
* Endcap cells are used to **fill the remaining space at the ends of standard cell rows** when the last standard cell doesn't perfectly fit in the row's length.
* They **provide electrical and physical isolation** between the active area of the silicon and the surrounding structures, suc has the scribe line or the edge of the die.

### 关于`addWellTap`命令

* Welltap cells **ensure proper electrical connection and prevent latch-up** in CMOS processes.
* Welltap cells help prevent latch-up by **providing a low-resistance path to ground or VDD for the substrate or well** in which transistors are fabricated.
* Welltaps are strategically placed throughout the IC layout, especially near power and ground connections. 
* Their placement is often governed by design rules specified by the foundry.

### 关于`addRing`命令

简单来说，在模块的四周，以及内部MACRO（例如SRAM/Register File）的四周需添加Power ring，用于给旁边的功能单元供电。

* A power ring **provides a continuous path for power and ground connections** around the periphery of the core area of the entire chip.
* This ring is essential for distributing power and ground connections uniformly across the chip to ensure that all parts of the IC receive a stable power supply and maintain a solid ground reference.
* Purpose and functionality: stable power supply, noise reduction, thermal management

### 关于`addStripe`命令

* A power stripe is a layout technique used to provide stable power (VDD) and ground (GND) connections to the various logic units and circuit blocks on the chip.
* Power stripes are implemented by introducing wide metal lines (stripes) into the chip layout that connect to the power and ground supply, ensuring that power distribution across the chip is uniform and grounding is effective.
* Benefits
	* Reducing Voltage Drop (IR Drop)
	* Reducing Electromagnetic Interference (EMI)
	* Improving Efficiency of Power Distribution
	* Power Management
* 简单来说，需要在版图的全部区域添加Power stripe
* 偶数层设置`-direction vertical`，奇数层设置`-direction horizontal`，由此构成Power mesh（供电网格）
* 为了避免底层金属布线过于密集，可以考虑在较低层金属（例如M6）设置较为稀疏的Power stripe，在较高层金属（例如M8）设置较为密集
* 后续使用`sroute`命令将Power stripe连接起来，只需连接到最低层的Power stripe即可。

### 关于`createPGPin`命令

* 将最顶层的金属走线作为P/G Pin，因此此处生成的P/G Pin需要和此前使用`addStripe`生成的P/G金属条保持重合。
* 因为需要保持一定间隔连续生成许多条P/G Pin，可以用一层For循环来减少工作量。

## 带有SRAM/Register File设计的后端流程

### 脚本调整
* 在`./scripts/design_input_macro.tcl`中添加SRAM/Register File的`LEF`
* 在`./scripts/tech.tcl`中添加SRAM/Register File的`LIB`
* 对于顶层模块的集成，如果有一些子模块已经完成后端，也需要在这两个位置分别加入`LIB`和`LEF`文件。实际上`LIB`文件应该在Genus综合前就添加，否则综合时无法读取其所需的时序信息。
* 连接Power
	* 在`./scripts/init_invs.tcl`中修改模块的P/G Connection。
	* 如果需要区分电源域，例如SRAM需要单独供电，则需要在此定义`VDD`, `VDD_SRAM`两个Power Net
```tcl
set init_pwr_net {VDD VDD_SRAM}
```

### 流程说明

此处以`Jan15_HuanCun`模块的后端流程为例

* **Start Innovus**
```bash
cd /work/home/ztzhu/my_projects/xiangshan/Jan15/backend_huancun/
gvim huancun_innovus_script.tcl & cd work
b innovus
```

* **Load design**
	在Innovus的命令行中输入如下命令，下同
```tcl
date
setMultiCpuUsage -localCpu 32
set start_time [clock seconds]
source -verbose ../scripts/core_config.tcl
source -verbose ../scripts/tech.tcl
source -verbose ../scripts/init_invs.tcl
source -verbose ../scripts/invs_settings.tcl
```

* **Set FloorPlan**
	*	根据Genus综合的面积报告以及整体版图规划选择版图的长和宽
	*	Innovus右上角的Floorplan View可以看到SRAM/Register File等MACRO的大小
	![Floorplan View](./figs/floorplan.png)
```tcl
set cell_height 0.7
set macro_halo_spc [expr 1 * $cell_height]
set macro_halo_spc_4 [expr 4 * $cell_height]
set macro_halo_spc_2 [expr 2 * $cell_height]
# set macro_halo_spc [expr 4 * $cell_height]
set die_sizex 900
set die_sizey 850
floorPlan -d $die_sizex $die_sizey 3.5 3.5 3.5 3.5
uiSetTool select
getIoFlowFlag
```

* **Place SRAM and other macros**
	* 见[place_macro.tcl](./my_scripts/place_macro.tcl)
```tcl
source ../scripts/place_macro.tcl
```
* **Add halos and routing blockage around macros**
	* 可以通过添加`RO R90 R180 MX MX90 MY MY90`等决定SRAM的摆放方向
	* 例如：`placeInstance $sram_macro 21.0 21.0 R180`
	* 需要注意，22nm工艺不支持90度旋转
```tcl
# add Halos around MACROS
setInstancePlacementStatus -allHardMacros -status fixed
addHaloToBlock [list $macro_halo_spc_4 $macro_halo_spc_4 $macro_halo_spc_4 $macro_halo_spc_4] -allMacro

# add Routing Blockage if necessary
for {set i 0 } {$i <= 7 } {incr $i} {
	set macroName "sram_$i"
	createRouteBlk -cover -inst [set $macroName] -layer {M1 M2 M3 M4 M5 M6 M7} -spacing $macro_halo_spc
}
for {set i 0 } {$i <= 6 } {incr $i} {
	set macroName "rf_$i"
	createRouteBlk -cover -inst [set $macroName] -layer {M1 M2 M3 M4 M5 M6 M7} -spacing $macro_halo_spc
}
```

* **Define P/G Connections**
	* 见[pg_pin.tcl](./my_scripts/pg_pin.tcl)
```tcl
source ../scripts/power_pins.tcl
```

* **Add Pins**
	* 使用`editPin`命令，见[add_pin.tcl](./my_scripts/add_pin.tcl)
```tcl
source ../scripts/add_pin.tcl
```

* **Add EndCaps, WellTaps**
```tcl
set itx $rm_tap_cell_distance
set tap_rule [expr $itx/4]

setPlaceMode -place_detail_legalization_inst_gap 2
setPlaceMode -place_detail_use_no_diffusion_one_site_filler false

setEndCapMode -reset
setEndCapMode -rightEdge $endcap_left -leftEdge $endcap_right
addEndCap

addWellTap -cell ${rm_tap_cell} -cellInterval $rm_tap_cell_distance -checkerboard
allWellTap -prefix DECAP -cellInterval $rm_tap_cell_distance -cell ${dcap_cell} -skipRow 1
```

* **Add Power Rings, Power Stripes**
	* 见[power_ring.tcl](./my_scripts/power_ring.tcl)
	* 应当可以看到走在SRAM/Register File MACRO上的Power。以下图为例，可以看到M6层的Power Stripe到M4层SRAM VDD的VIA，说明给该MACRO提供了供电。
```tcl
source ../scripts/power_ring.tcl

# add power stripes at four sides of SRAM
# M6 (Vertical)
addStripe -start_offset 0.7 -direction vertical -block_ring_top_layer_limit M6 -padcore_ring_bottom_layer M1 -set_to_set_distance 30 -stacked_via_top_layer M6 -padcore_ring_top_layer_limit M6 -spacing 15 -layer M6 -block_ring_bottom_layer_limit M1 -width 2 -nets {VSS, VDD_SRAM} -stacked_via_bottom_layar M1

# M7 (Horizontal)
addStripe -start_offset 0.7 -direction horizontal -block_ring_top_layer_limit M7 -padcore_ring_bottom_layer M6 -set_to_set_distance 20 -stacked_via_top_layer M7 -padcore_ring_top_layer_limit M7 -spacing 10 -layer M7 -block_ring_bottom_layer_limit M6 -width 2 -nets {VSS, VDD_SRAM} -stacked_via_bottom_layar M6

# M8 (Vertical)
addStripe -start_offset 10 -direction vertical -block_ring_top_layer_limit M8 -padcore_ring_bottom_layer M6 -set_to_set_distance 20 -stacked_via_top_layer M8 -padcore_ring_top_layer_limit M8 -spacing 10 -layer M8 -block_ring_bottom_layer_limit M6 -width 2 -nets {VSS, VDD_SRAM} -stacked_via_bottom_layar M6

sroute -connect { corePin } -layerChangeRange { M1 M6 } -blockPinTarget { nearestRingStripe nearestTarget } -padPinPortConnect { allPort oneGeom } -checkAlignedSecondaryPin 1 -blockPin useLef  -allowJogging 0 -crossoverViaBottomLayer M1 -allowLayerChange 1 -targetViaTopLayer M6 -crossoverViaTopLayer M6 -targetViaBottomLayer M1 -nets {VDD VSS VDD_SRAM}

editPowerVia -skip_via_on_pin Standardcell -bottom_layer M1 -add_vias 1 -top_layer M6
```

* **Placement**
	* `-routeTopRoutingLayer 7`说明允许信号线最高使用M7层的金属。根据整体版图情况，可以选择M5-M7层作为布信号线所允许的最高层金属。通常来说，版图最高层金属只会有P/G电源线，在此例中，为M8层金属。
	* `-routeBottomRoutingLayer 2`说明允许信号线最低使用M2层的金属。
```tcl
setTieHiLoMode  -cell $rm_tie_hi_lo_list \
								-maxFanout 8
deleteTieHiLo

setPlaceMode -reset
setPlaceMode -place_detail_legalization_inst_gap 2
setPlaceMode -place_detail_use_no_diffusion_one_site_filler false

# to address the issue regarding scan chains
# setPlaceMode -place_global_ignore_scan false

setNanoRouteMode -routeTopRoutingLayer 7
setNanoRouteMode -routeBottomRoutingLayer 2
setPlaceMode -fp false
setAnalysisMode -aocv false

placeDesign
addTieHiLo

place_opt_design -incremental  -out_dir ../reports/layout/INNOVUS_RPT -prefix place
timeDesign -preCTS -outDir ../reports/layout/INNOVUS_RPT

# preCTS reports
set myOption "preCTS"
source ../scripts/intermediate_reporting.tcl
```

* **Clock Tree Synthesis (CTS)**

```tcl
set_ccopt_property -update_io_latency true
set_ccopt_property -force_update_io_latency true
set_ccopt_property -enable_all_views_for_io_latency_update true
set_ccopt_property -max_fanout ${rm_cts_max_fanout}
set_ccopt_property -effort high
set_ccopt_property buffer_cells $rm_clock_buf_cap_cell
set_ccopt_property inverter_cells $rm_clock_inv_cap_cell
set_ccopt_property clock_gating_cells $rm_clock_icg_cell

set_ccopt_mode -cts_use_min_max_path_delay false \
								-cts_target_slew $rm_max_clock_transition \
								-cts_target_skew 0.15 \
								-modify_clock_latency false

# set_ccopt_property balance_mode cluster
create_ccopt_clock_tree_spec -file ../data/${rm_core_top}-ccopt_cts.spec
create_ccopt_clock_tree_spec

ccopt_design -check_prerequisites
ccopt_design -outDir ../reports/layout/INNOVUS_RPT -prefix ccopt

# Report design after CTS
set myOption "clocks"
source ../scripts/intermediate_reporting.tcl
```

* **Route**
```tcl
setExtractRCMode -engine postRoute -effortLevel medium -tQuantusForPostRoute true

set NanoRouteMode -routeWithTimingDriven true \
								-routeWithSiDriven true \
								-routeWithLithoDriven false \
							-routeDesignRouteClockNetsFirst true \
								-routeReserveSpaceForMultiCut false \
								-drouteUseMultiCutViaEffort low \
							-drouteFixAntenna true

routeDesign
```

* **Post-route**
```tcl
setExtractRCMode -engine postRoute -effortLeve medium -tQuantusForPostRoute true
setOptMode -verbose true
setOptMode -highEffortOptCells $hold_fixing_cells
setOptMode -holdFixingCells $hold_fixing_cells
optDesign -postRoute -drv
optDesign -postRoute -incr
optDesign -postRoute -hold

timeDesign -postRoute -outDir ../reports/layout/INNOVUS_RPT
timeDesign -postRoute -hold -outDir ../reports/layout/INNOVUS_RPT

# Report design after routing
set myOption "postRoute"
source ../scripts/intermediate_reporting.tcl

# Incrementtal routing to fix shorts
addTieHiLo

setNanoRouteMode -routeWithEco true -drouteFixAntenna true -routeInsertAntennaDiode true
globalDetailRoute
```

* **Add Filler Cells**
```tcl
setFillerMode -scheme locationFirst \
						-minHole true \
						-fitGap true \
						-diffCellViol true

addFiller -cell $rm_fill_cells
ecoRoute -fix_drc

setFillerMode -ecoMode true
addFiller -fixDRC -fitGap -cell $rm_fill_cells
```

* **Create P/G Pins**
	* 在此处定义的P/G管脚与此前定义的最顶层的Power Stripe重叠。在此例中，是M8层金属。
```tcl
# create PG Pins
for { set i 0} {$i <= 22 } {incr i} {
	set initX [expr 10 + $i * 40]
	set initY 3.5
	set stripeHeight 843
	set stripeWidth 2	
	createPGPin VDD -geom M8 $initX $initY [expr $initX + $stripeWidth] [expr $initY + $stripeHeight]
}

for { set i 0 } {$i <= 22 } {incr i} {
set initX [expr 20 + $i * 40]
set initY 3.5
set stripeHeight 843
set stripeWidth 2  
createPGPin VDD -geom M8 $initX $initY [expr $initX + $stripeWidth] [expr $initY + $stripeHeight]
}
```

* **Generate Files**
```tcl
write_lef_abstract -5.8 -specifyTopLayer M8 \
					-PGpinLayers {M8} -stripePin \
					-cutObsMinSpacing \
				../models/lef/${rm_core_top}.lef

write_sdf -min_view ff_0p88v_125c_view \
		-typ_view tt_0p80v_25c_view \
		-max_view ss_0p72v_m40c_view \
		-recompute_parallel_arcs ../models/sdf/${rm_core_top}.sdf

write_sdc ../models/sdc/${rm_core_top}.sdc

streamOut -mapFile ${rm_lef_layer_map} ../data/${rm_core_top}.gds2 -mode ALL \
		-merge "/work/home/wumeng/pdks/tsmc/tsmc22ull/tcbn22ullbwp7t30p140lvt_110a/digital/Back_End/gds/tcbn22ullbwp7t30p140lvt_110a/tcbn22ullbwp7t30p140lvt.gds"
		/path/to/my/sram/gds \
		/path/to/my/macro/gds" 

saveNetlist ../data/${rm_core_top}.pg.flat.v -flat -phys -excludeLeafCell -excludeCellInst $lvs_exclude_cells
```

* **Signoff**
```tcl
# save the design for signoff
saveDesign ${rm_core_top}.signoff.enc

set stop_time [clock seconds]
set elapsedTime [clock format [expr $stop_time - $start_time] -format %H:%M:%S -gmt true]
puts "=============================================="
puts "        Elapsed runtime : $elapsedTime"
puts "=============================================="

date
```

## 一些常见报错说明

### IMPSP-9099

* ERROR: (IMPSP-9099): Scan chains exist in this design but are not defined for xx% flops
* 在`placeDesign`步骤中遇到了这个报错。
* 扫描链（Scan Chain）是一种常用的数字集成电路（IC）测试技术，属于设计可测试性（Design for Testability, DFT）的范畴。扫描链技术是为了简化数字逻辑电路的测试而引入的，它可以让测试人员更容易地访问和控制芯片内部的触发器（Flip-Flops）
* 可能的解决方法：
	* 在`placeDesign`前添加参数选项：`setPlaceMode -place_global_ignore_scan false`
	* 参考[这篇论坛提问][IMPSP-9099:solution]
* **不理会这个报错也不影响后续流程**

[IMPSP-9099:solution]: https://community.cadence.com/cadence_technology_forums/f/digital-implementation/57299/error-impsp-9099-scan-chains-exist-in-this-design-but-are-not-defined-for-xx-flops
