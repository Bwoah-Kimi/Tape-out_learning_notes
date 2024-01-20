# Innovus learning notes

## 基础后端流程

1. 打开Innovus和流程Scripts
	```bash
	cd work
	b innovus
	gvim ../scripts/innovus_scripts.tcl
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
* 在Power routing中，通常预留最顶层的两层金属作为最终设计的电源连接。
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
 
## 简单流程一步到位

* `b make innovus_backend`完成全部的后端流程
* `win`打开Innovus GUI


## 带有SRAM设计的后端流程

1. 脚本调整
	* 在`./scripts/design_input_macro.tcl`中添加SRAM的LEF
	* 在`./scripts/tech.tcl`中添加SRAM的LIB
	* 连接SRAM的Power，在`./scripts/init_invs.tcl`中定义SRAM的VDD
	```tcl
	set init_pwr_net {VDD VDD_SRAM}
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
	*	Innovus右上角的Floorplan View可以看到SRAM大小
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
	* 可以看到SRAM的Power通过Via从M4连接到M6的VDD_SRAM	上

7. Placement
	```tcl
	
