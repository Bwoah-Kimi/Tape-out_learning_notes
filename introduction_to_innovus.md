# Innovus learning notes

* 此处分两部分介绍了Innovus后端流程，一部分是基础流程，一部分是带有SRAM/Register File的后端流程，后者适用性更强，可以主要参考后者的流程。
* 运行Innovus后端需要在Genus synthesis完成的基础上进行。
* 脚本中许多的参数设置，例如width, spacing，以及MACRO的位置摆放需要根据版图大小以及布线情况来设定，需多次迭代优化。

## 部分命令说明

* 在讲述具体的后端流程之前，有必要对一些命令进行说明，或许会对后端流程debugging有一定帮助
* 在运行过程中，如果碰到报错，或者对于某些命令参数选项不确定，可以在Innovus命令行中输入`man <CMDName>`来查看官方Manual以获得相应信息。
* 个人经验感觉，对于命令的说明较为清晰，配合ChatGPT可以获得较好的效果，而对于报错信息，官方手册以及网络信息都比较欠缺，需更有针对性进行查找。

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
	 * Use thisoption to block signal routing above or around a sensitive block to avoid noise from nearby signal nets but still allow power connections to go through the blockage.
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

** 简单来说，在模块的四周，以及内部MACRO（例如SRAM/Register File）的四周需添加Power ring，用于給旁边的功能单元供电
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

## 基础后端流程

以build_adder的tutorial为例，目录位置为：`/work/home/ztzhu/my_projects/tutorials/build_adder_sram_backend/`

1. 打开Innovus和流程Scripts
	```bash
	cd work
 	vim ../scripts/innovus_scripts.tcl
	b innovus
	
	```

2. 载入综合后的网表 xxx.v
	```tcl
	date
	setMultiCpuUsage -localCpu max -cpuAutoAdjust true -verbose
	
	set start_time [clock seconds]
	
	# setup the configuration
	source -verbose ../scripts/core_config.tcl
	
	# setup the target technology
	source -verbose ../scripts/tech.tcl
	
	# initialize design
	source -verbose ../scripts/init_invs.tcl
	```

3. FloorPlan：设定面积大小，定义长和宽
	```tcl
	set cell_height 0.7
	set die_sizex [expr 50 * $cell_height]
	set die_sizey [expr 50 * $cell_height]
	
	floorPlan -d $die_sizex $die_sizey 3.5 3.5 3.5 3.5
	uiSetTool select
	getIoFlowFlag
	```

4. 定义Power连接、Pin的连接位置、添加WellTap
	```tcl
	globalNetConnect VDD -type pgpin -pin VDD -all -override
	globalNetConnect VSS -type pgpin -pin VSS -all -override
	globalNetConnect VDD -type tiehi
	globalNetConnect VSS -type tielo
	
	source ../scripts/add_pin.tcl
	
	set itx $rm_tap_cell_distance
	set tap_rule [expr $itx/4]
	
	setPlaceMode -place_detail_legalization_inst_gap 2
	setPlaceMode -place_detail_use_no_diffusion_one_site_filler false
	
	addWellTap -cell ${rm_tap_cell} -cellInterval $rm_tap_cell_distance -checkerboard
	allWellTap -prefix DECAP -cellInterval $rm_tap_cell_distance -cell ${dcap_cell} -skipRow 1
	```

5. 连接Power rail，连接Power ring
	```tcl
	setAddRingMode -avoid_short true
	addRing -nets [lists VDD VSS] -type core_rings -follow core -layer {top M5 bottom M5 left M6 right M6} -width 0.7 -spacing 0.35 -spacing 0.35 -center 0
	addStripe -start_offset 0.7 -direction vertical -block_ring_top_layer_limit M8 -padcore_ring_bottom_layer_limit M1 -set_to_set_distance 7 -stacked_via_top_layer M8 -padcore_ring_top_layer_limit M8 -spacing 0.7 -layer M8 -block_ring_bottom_layer_limit M1 -width 1.4 -nets { VDD VSS } -stacked_via+bottom_layer M1
	
	sroute -connect { corePin } -layerChangeRange { M1 M6 } -blockPinTarget { nearestRingStripe nearestTarget } -padPinPortConnect { allPort oneGeom } -checkAlignedSecondaryPin 1 -blockPin useLef  -allowJogging 0 -crossoverViaBottomLayer M1 -allowLayerChange 1 -targetViaTopLayer M6 -crossoverViaTopLayer M6 -targetViaBottomLayer M1 -nets {VDD VSS}
	
	editPowerVia -skip_via_on_pin Standardcell -bottom_layer M1 -add_vias 1 -top_layer M6
	
	setEndCapMode -reset
	setEndCapMode -boundary_tap false
	```

	* 奇数层为横向金属，偶数层为纵向金属。
	* 在Power routing中，通常预留最顶层的**两层金属**作为最终设计的电源连接。
		* 在此22nm工艺中，**顶层金属为AP(8)**，因此预留M7、AP作为顶层电源连接。
		* **每个数字模块的最顶层金属为M6**

6. Placement
	```tcl
	setTieHiLoMode  -cell $rm_tie_hi_lo_list \
									-maxFanout 8
	deleteTieHiLo
	
	setPlaceMode -reset
	setPlaceMode -place_detail_legalization_inst_gap 2
	setPlaceMode -place_detail_use_no_diffusion_one_site_filler false
	
	setNanoRouteMode -routeTopRoutingLayer 5
	setNanoRouteMode -routeBottomRoutingLayer 2
	setPlaceMode -fp false
	setAnalysisMode -aocv false
	
	placeDesign
	place_opt_design -incremental  -out_dir ../reports/layout/INNOVUS_RPT -prefix place
	timeDesign -preCTS -outDir ../reports/layout/INNOVUS_RPT
	```

7. Clock Tree Synthesis
	```tcl
	set_ccopt_property -update_io_latency true
	set_ccopt_property -force_update_io_latency true
	set_ccopt_property -enable_all_views_for_io_latency_update true
	set_ccopt_property -max_fanout ${rm_cts_max_fanout}
	set_ccopt_property -effort high
	set_ccopt_property buffer_cells $rm_clock_buf_cap_cell
	set_ccopt_property inverter_cells $rm_clock_inv_cap_cell
	set_ccopt_property clock_gating_cells $rm_clock_icg_cell
	
	set_ccopt_mode  -cts_use_min_max_path_delay false \
									-cts_target_slew $rm_max_clock_transition \ 
				   				-cts_target_skew 0.15 \ 
				   				-modify_clock_latency false
	
	create_ccopt_clock_tree_spec -file ../data/${rm_core_top}-ccopt_cts.spec
	create_ccopt_clock_tree_spec
	
	ccopt_design -check_prerequisites
	ccopt_design -outDir ../reports/layout/INNOVUS_RPT -prefix ccopt
	```

8. Routing, Setup/hold timing optimization
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
	
	setExtractRCMode -engine postRoute -effortLeve medium -tQuantusForPostRoute true
	setOptMode -verbose true
	setOptMode -highEffortOptCells $hold_fixing_cells
	setOptMode -holdFixingCells $hold_fixing_cells
	optDesign -postRoute -drv
	optDesign -postRoute -incr
	optDesign -postRoute -hold
	```

	* 可以通过简单的命令快速查看timing
	* `report_timing`来查看setup timing
	* `report_timing -early`来查看hold timing

9. Signoff：添加Filler，再次修复DRC
	```tcl
	setNanoRouteMode -routeWithEco true -drouteFixAntenna true -routeInsertAntennaDiode true
	globalDetailRoute
	
	setFillerMode -scheme locationFirst \
		      			-minHole true \
		      			-fitGap true \
		      			-diffCellViol true
	
	addFiller -cell $rm_fill_cells
	ecoRoute -fix_drc
	
	setFillerMode -ecoMode true
	addFiller -fixDRC .fitGap -cell $rm_fill_cells
	```

## 带有SRAM/Register File设计的后端流程

### 脚本调整
* 在`./scripts/design_input_macro.tcl`中添加SRAM的LEF
* 在`./scripts/tech.tcl`中添加SRAM的LIB
* 连接Power
* 如果SRAM的电源为VDD_SRAM，其余单元的电源为VDD，在`./scripts/init_invs.tcl`中修改：
	```tcl
	set init_pwr_net {VDD VDD_SRAM}
	```
* 如果模块中单元与SRAM Macro统一供电，则将上述`init_pwr_net`名字修改与RTL代码保持一致即可

### 流程说明

此处以HuanCun模块的后端流程为例

1. 启动Innovus
	```bash
	cd /work/home/ztzhu/my_projects/xiangshan/backend_huancun_sram_rf/
	vim huancun_innovus_script.tcl
	cd work
	b innovus
	```

2. 载入设计
	```tcl
	date
	setMultiCpuUsage -localCpu max -cpuAutoAdjust true -verbose
	set start_time [clock seconds]
	source -verbose ../scripts/core_config.tcl
	source -verbose ../scripts/tech.tcl
	source -verbose ../scripts/init_invs.tcl
	```

3. FloorPlan调整
	*	根据SRAM的大小和长宽选择版图面积
	*	Innovus右上角的Floorplan View可以看到SRAM/Register File等MACRO的大小
	```tcl
	set cell_height 0.7
 	set macro_halo_spc [expr 4 * $cell_height]
	set die_sizex [expr 250 * $cell_height]
	set die_sizey [expr 350 * $cell_height]
	
	floorPlan -d $die_sizex $die_sizey 3.5 3.5 3.5 3.5
	uiSetTool select
	getIoFlowFlag
	```

4. 放置SRAM
	```tcl
	set sram_macro SRAM
	placeInstance $sram_macro 21.0 21.0
	
	# add Halos around MACROS
	setInstancePlacementStatus -allHardMacros -status fixed
	addHaloToBlock [list $macro_halo_spc $macro_halo_spc $macro_halo_spc $macro_halo_spc] -allMacro
	createRouteBlk -cover -inst $sram_macro -pgnetonly -layer {M1 M2 M3 M4 M5 M6} -spacing $macro_halo_spc
	```
	* 可以通过添加`RO R90 R180 MX MX90 MY MY90`等决定SRAM的摆放方向
	* 例如：`placeInstance $sram_macro 21.0 21.0 R180`

5. 定义Power连接和WellTap
	```tcl
	globalNetConnect VDD -type pgpin -pin VDD -all -override
	globalNetConnect VSS -type pgpin -pin VSS -all -override
	globalNetConnect VDD -type tiehi
	globalNetConnect VSS -type tielo
	
	# SRAM Power
	globalNetConnect VDD_SRAM -type pgpin -pin VDD_SRAM -sinst $sram_macro
	
	source ../scripts/add_pin.tcl
	
	set itx $rm_tap_cell_distance
	set tap_rule [expr $itx/4]
	
	setPlaceMode -place_detail_legalization_inst_gap 2
	setPlaceMode -place_detail_use_no_diffusion_one_site_filler false
	
	addWellTap -cell ${rm_tap_cell} -cellInterval $rm_tap_cell_distance -checkerboard
	allWellTap -prefix DECAP -cellInterval $rm_tap_cell_distance -cell ${dcap_cell} -skipRow 1
	```

6. 添加Power Straps
	```tcl
	# core ring
	setAddRingMode -avoid_short true
	addRing -nets [lists VDD VDD_SRAM VSS] -type core_rings -follow core -layer {top M5 bottom M5 left M4 right M4} -width 0.7 -spacing 0.35 -center 0

	# add power straps at both sides of SRAM
	selectInst $sram_macro
	addRing -nets {VSS VDD} -type block_rings -around selected -layer {top M5 bottom M5 left M4 right M4} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.14 bottom 0.14 left 0.7 right 0.7} -center 0
	
	addStripe -start_offset 0.7 -direction vertical -block_ring_top_layer_limit M6 -padcore_ring_bottom_layer_limit M1 -set_to_set_distance 7 -stacked_via_top_layer M6 -padcore_ring_top_layer_limit M6 -spacing 0.7 -layer M6 -block_ring_bottom_layer_limit M1 -width 1.4 -nets { VDD VSS VDD_SRAM} -stacked_via_bottom_layer M1
	
	sroute -connect { corePin } -layerChangeRange { M1 M6 } -blockPinTarget { nearestRingStripe nearestTarget } -padPinPortConnect { allPort oneGeom } -checkAlignedSecondaryPin 1 -blockPin useLef  -allowJogging 0 -crossoverViaBottomLayer M1 -allowLayerChange 1 -targetViaTopLayer M6 -crossoverViaTopLayer M6 -targetViaBottomLayer M1 -nets {VDD VSS VDD_SRAM}
	
	editPowerVia -skip_via_on_pin Standardcell -bottom_layer M1 -add_vias 1 -top_layer M6
	
	setEndCapMode -reset
	setEndCapMode -boundary_tap false
	```
	* 可以看到SRAM的Power通过Via从M4连接到M6的VDD_SRAM上

7. Placement
	```tcl
	setTieHiLoMode  -cell $rm_tie_hi_lo_list \
									-maxFanout 8
	deleteTieHiLo
	
	setPlaceMode -reset
	setPlaceMode -place_detail_legalization_inst_gap 2
	setPlaceMode -place_detail_use_no_diffusion_one_site_filler false
	
	setNanoRouteMode -routeTopRoutingLayer 5
	setNanoRouteMode -routeBottomRoutingLayer 2
	setPlaceMode -fp false
	setAnalysisMode -aocv false
	
	placeDesign
	place_opt_design -incremental  -out_dir ../reports/layout/INNOVUS_RPT -prefix place
	timeDesign -preCTS -outDir ../reports/layout/INNOVUS_RPT
	```

8. Routing
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
	
	setExtractRCMode -engine postRoute -effortLeve medium -tQuantusForPostRoute true
	setOptMode -verbose true
	setOptMode -highEffortOptCells $hold_fixing_cells
	setOptMode -holdFixingCells $hold_fixing_cells
	optDesign -postRoute -drv
	optDesign -postRoute -incr
	optDesign -postRoute -hold
	```

 9. Signoff
	```tcl
	setNanoRouteMode -routeWithEco true -drouteFixAntenna true -routeInsertAntennaDiode true
	globalDetailRoute
	
	setFillerMode -scheme locationFirst \
		      			-minHole true \
		      			-fitGap true \
		      			-diffCellViol true
	
	addFiller -cell $rm_fill_cells
	ecoRoute -fix_drc
	
	setFillerMode -ecoMode true
	addFiller -fixDRC .fitGap -cell $rm_fill_cells
	```
