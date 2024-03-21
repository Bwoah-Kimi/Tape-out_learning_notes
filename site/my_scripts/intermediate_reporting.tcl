
switch -- $myOption {
	"preCTS" {
		puts "preCTS reporting"
		report_timing -max_paths 200      > ../reports/layout/${rm_core_top}-placeopt.timing
		report_constraint -all_violators        > ../reports/layout/${rm_core_top}-placeopt.constraint
		report_area -out_file                ../reports/layout/${rm_core_top}-placeopt.area
		report_design                      > ../reports/layout/${rm_core_top}-placeopt.design
		reportFanoutViolation -max         -outfile ../reports/layout/${rm_core_top}-placeopt.fanout
		reportCongestion -hotSpot -includeBlockage -overflow \
		                                   > ../reports/layout/${rm_core_top}-placeopt.congestion
		
		# Report inactive arcs for the design
		report_inactive_arcs -delay_arcs_only > ../reports/layout/${rm_core_top}-placeopt.disable_timing
		
		# Check for ignored nets for optimization
		reportIgnoredNets                 -outfile ../reports/layout/${rm_core_top}-placeopt.ignored_nets
		
		# Report case analysis in the design
		report_case_analysis -all -nosplit \
		                               > ../reports/layout/${rm_core_top}-placeopt.set_case
	}
	
	"clocks" {
		puts "reporting clocks"
		report_ccopt_clock_trees -filename ../reports/layout/${rm_core_top}-clockopt.clock_trees
		report_ccopt_skew_groups -filename ../reports/layout/${rm_core_top}-clockopt.skew_groups
		report_ccopt_clock_tree_structure -file ../reports/layout/${rm_core_top}-clockopt.clock_tree_structure
		
		# Intermediate reporting
		report_timing -max_paths 200       > ../reports/layout/${rm_core_top}-clockopt.timing
		report_constraint -all_violators        > ../reports/layout/${rm_core_top}-clockopt.constraint
		
		# Report inactive arcs for the design
		report_inactive_arcs -delay_arcs_only > ../reports/layout/${rm_core_top}-clockopt.disable_timing
		
		# Check for ignored nets for optimization
		reportIgnoredNets                 -outfile ../reports/layout/${rm_core_top}-clockopt.ignored_nets
	}

	"postRoute" {
		puts "postRoute reporting"
		report_timing -max_paths 200       > ../reports/layout/${rm_core_top}-routeopt.timing
		report_constraint -all_violators        > ../reports/layout/${rm_core_top}-routeopt.constraint
		
		report_timing -late -path_group C2C -path_type full_clock -max_paths 10 > ../reports/layout/C2C_late_routeopt.tarpt
		report_timing -late -path_group I2C -path_type full_clock -max_paths 10 > ../reports/layout/I2C_late_routeopt.tarpt
		report_timing -late -path_group C2O -path_type full_clock -max_paths 10 > ../reports/layout/C2O_late_routeopt.tarpt
		
		report_timing -early -path_group C2C -path_type full_clock -max_paths 10 > ../reports/layout/C2C_early_routeopt.tarpt
		report_timing -early -path_group I2C -path_type full_clock -max_paths 10 > ../reports/layout/I2C_early_routeopt.tarpt
		report_timing -early -path_group C2O -path_type full_clock -max_paths 10 > ../reports/layout/C2O_early_routeopt.tarpt
		
		# Report inactive arcs for the design
		report_inactive_arcs -delay_arcs_only > ../reports/layout/${rm_core_top}-routeopt.disable_timing
		
		# Check for ignored nets for optimization
		reportIgnoredNets                 -outfile ../reports/layout/${rm_core_top}-routeopt.ignored_nets
	}

	default {
		puts "Unknown option: $myOption"
		exit 1
	}
}
