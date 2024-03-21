# SRAM
# 2048x64
set sram_0 slices_0/dataStorage/bankedData_0_banks_0_array_array_23_ext_SRAM
set sram_1 slices_0/dataStorage/bankedData_1_banks_0_array_array_23_ext_SRAM
set sram_2 slices_0/dataStorage/bankedData_2_banks_0_array_array_23_ext_SRAM
set sram_3 slices_0/dataStorage/bankedData_3_banks_0_array_array_23_ext_SRAM
set sram_4 slices_0/dataStorage/bankedData_4_banks_0_array_array_23_ext_SRAM
set sram_5 slices_0/dataStorage/bankedData_5_banks_0_array_array_23_ext_SRAM
set sram_6 slices_0/dataStorage/bankedData_6_banks_0_array_array_23_ext_SRAM
set sram_7 slices_0/dataStorage/bankedData_7_banks_0_array_array_23_ext_SRAM
# RF
# 256x7
set rf_0 slices_0/directory/selfDir/repl_state_replacer_sram/array_array_27_ext_register_file
# 256x16
set rf_1 slices_0/directory/clientDir/metaArray_array_array_24_ext_register_file
# 256x40
set rf_2 slices_0/directory/selfDir/metaArray_array_array_26_ext_register_file
# 256x88
set rf_3 slices_0/directory/selfDir/tagArray/array_array_25_ext_register_file_1
set rf_4 slices_0/directory/selfDir/tagArray/array_array_25_ext_register_file_0
set rf_5 slices_0/directory/clientDir/tagArray/array_array_25_ext_register_file_1
set rf_6 slices_0/directory/clientDir/tagArray/array_array_25_ext_register_file_0

set x_1 40.0
set xInterval 240.0
set y_1 40.0
set yInterval 280.0

placeInstance $sram_0 $x_1 $y_1 R180
placeInstance $sram_1 $x_1 [expr $y_1 + $yInterval] R180
placeInstance $sram_2 $x_1 [expr $y_1 + 2 * $yInterval] R180
placeInstance $sram_5 [expr $x_1 + $xInterval] $y_1 R180
placeInstance $sram_4 [expr $x_1 + $xInterval] [expr $y_1 + $yInterval] R180
placeInstance $sram_3 [expr $x_1 + $xInterval] [expr $y_1 + 2 * $yInterval]
placeInstance $sram_6 [expr $x_1 + 2 * $xInterval + 180.0] $y_1
placeInstance $sram_7 [expr $x_1 + 2 * $xInterval + 180.0] [expr $y_1 + $yInterval]

set baseX [expr $x_1 + 1.95 * $xInterval]
set baseY [expr $y_1 + 2 * $yInterval]
set xInterval 100.0
placeInstance $rf_3 $baseX $baseY R180
placeInstance $rf_4 [expr $baseX + $xInterval] $baseY 
placeInstance $rf_5 [expr $baseX + 2 * $xInterval] $baseY R180
placeInstance $rf_6 [expr $baseX + 3 * $xInterval] $baseY
set xInterval 120.0
placeInstance $rf_0 [expr $baseX + 0.2 * $xInterval] $y_1 R180
placeInstance $rf_1 [expr $baseX + 0.2 * $xInterval] [expr $y_1 + 110.0] R180
placeInstance $rf_2 [expr $baseX + 0.2 * $xInterval] [expr $y_1 + $yInterval]  R180