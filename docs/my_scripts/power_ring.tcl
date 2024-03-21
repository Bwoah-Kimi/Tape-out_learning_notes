# add core ring
setAddRingMode -avoid_short true
addRing -nets [list VDD_SRAM VSS] -type core_rings -follow core -layer {top M5 bottom M5 left M6 right M6} -width 0.35 -spacing 0.35 -center 0

# add power ring around SRAM and RF
selectInst $sram_0
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $sram_1
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $sram_2
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $sram_3
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $sram_4
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $sram_5
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $sram_6
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $sram_7
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $rf_0
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $rf_1
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $rf_2
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $rf_3
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $rf_4
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $rf_5
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

selectInst $rf_6
addRing -nets {VDD_SRAM VSS} -type block_rings -around selected -layer {top M5 bottom M5 left M6 right M6} -width {top 0.14 bottom 0.14 left 0.7 right 0.7} -spacing {top 0.14 bottom 0.14 left 0.35 right 0.35} -offset {top 0.84 bottom 0.84 left 0.7 right 0.7} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

