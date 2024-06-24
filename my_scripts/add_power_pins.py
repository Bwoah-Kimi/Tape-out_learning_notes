# add power pins to specific modules in a Verilog design

'''
Usage:

1. Specify the directory containing Verilog files that need to be modified
2. Specify the output directory of the modified Verilog files. Note that the output directory should be different from the original one.
3. Specify the base modules that serve as the beginning of the recursion process, i.e. array modules
4. Specify the top module of the design that serves as the end point of the recursion process.

'''

# Here is an example of a Verilog file.
# 
# module array_18_ext(
#   inout VDD, // add power pin
#   inout VSS, // add ground pin
#   input RW0_clk,
#   input [5:0] RW0_addr,
#   input RW0_en,
#   input RW0_wmode,
#   input [7:0] RW0_wmask,
#   input [183:0] RW0_wdata,
#   output [183:0] RW0_rdata
# );
# Here is an example of power connections
#  array_18_ext array_18_ext_instantiation (
#    .VDD(VDD),
#    .VSS(VSS),
#    .RW0_addr(array_18_ext_RW0_addr),
#    .RW0_en(array_18_ext_RW0_en),
#    .RW0_clk(array_18_ext_RW0_clk),
#    .RW0_wmode(array_18_ext_RW0_wmode),
#    .RW0_wdata(array_18_ext_RW0_wdata),
#    .RW0_rdata(array_18_ext_RW0_rdata),
#    .RW0_wmask(array_18_ext_RW0_wmask)
# );

import os
import re


# Directory containing the Verilog files
verilogDir = '/home/bwoah/xs-env/XiangShan_64KBL2_64KBL3/test'
# Directory to output the modified Verilog files
outputDir = '/home/bwoah/xs-env/XiangShan_64KBL2_64KBL3/test-out'
if outputDir == verilogDir:
    print("Output directory should be different from the original one!")
    exit(1)
# Base modules to add power pins
baseModules = ['array_21_ext','array_18_ext','array_19_ext', 'array_20_ext']
# Top module of the design
# If the top module is encountered, stop the recursion
topModule = 'Mar02_CoupledL2'

# Parse Verilog files to find module definitions and instantiations
def parseVerilogFiles(directory):
    moduleDeps = {}
    for filename in os.listdir(directory):
        if filename.endswith('.v'):
            with open(os.path.join(directory, filename), 'r') as file:
                content = file.read()
                # Regex to find module name and instances
                moduleNameMatch = re.search(r'module\s+(\w+)', content)
                if moduleNameMatch:
                    moduleName = moduleNameMatch.group(1)
                    # # Log the module name
                    # print("Found module", moduleName)
                    
                    # Find all module instantiations
                    instances = re.findall(r'(\w+)\s+\w+\s*\(', content)
                    
                    # Buggy code, 'module', 'end', 'begin', 'else', 'RANDOMIZE_REG_INIT'  will also be captured. Exclude them
                    instances = [instance for instance in instances if instance != 'module' and instance != 'end'and instance != 'begin' and instance != 'else' and instance != 'RANDOMIZE_REG_INIT']
                    
                    # Check if there are identical instances in the list
                    moduleDeps[moduleName] = list(set(instances))
    return moduleDeps

# Find parent modules
def findParentModules(moduleDeps, module):
    parentModules = []
    for parent, children in moduleDeps.items():
        if module in children:
            parentModules.append(parent)
    return parentModules

# Find modules that need power pins
modulesToUpdate = {}
def findModulesNeedingPowerPins(moduleDeps, curModule):
    if curModule == topModule:
        print(f"Reached top module {topModule}, stopping recursion")
        return
    parentModules = findParentModules(moduleDeps, curModule)
    # Log the parent modules found
    print(f"Parent modules of {curModule}: {parentModules}")
    for parent in parentModules:
        if parent not in modulesToUpdate:
            modulesToUpdate[parent] = []
        modulesToUpdate[parent].append(curModule)
        findModulesNeedingPowerPins(moduleDeps, parent)
    return

# Add power pins and connections to the modules
def addPowerPins(modulesToUpdate, moduleDeps):
    for module, submodules in modulesToUpdate.items():
        with open(os.path.join(verilogDir, module + '.v'), 'r') as file:
            lines = file.readlines()
            
            # Check if the module already has power pins
            hasPowerPins = False
            hasGroundPins = False
            for line in lines:
                if 'inout VDD' in line:
                    hasPowerPins = True
                if 'inout VSS' in line:
                    hasGroundPins = True
                if hasPowerPins and hasGroundPins:
                    break

            if not hasPowerPins and not hasGroundPins:
                # Add power pins afther the line of the module name
                for i, line in enumerate(lines):
                    pattern = re.compile(r'module\s+' + module + r'\s*\(')
                    if pattern.match(line):
                        # Log the modified module
                        print("Adding power pins to", module)
                        lines.insert(i + 1, '  inout VDD, // add power pin\n')
                        lines.insert(i + 2, '  inout VSS, // add ground pin\n')
                        break
        
            # Add power connections to the submodules
            for submodule in submodules:
                # Find the instantiation line
                pattern = re.compile(r'\s+' + submodule + r'\s+\w+\s*\(')
                for i, line in enumerate(lines):
                    if pattern.match(line):
                        # Capture the instance name of the submodule, the string after the submodule name
                        # e.g. array_18 array_18_instantiation (caputre array_18_instantiation)
                        instanceName = re.search(r'\s+(\w+)\s+\w+\s*\(', line).group(1)
                        # Check if power connection is already made
                        hasPowerConnection = False
                        hasGroundConnection = False
                        if '.VDD(VDD)' in lines[i+1]:
                            hasPowerConnection = True
                        if '.VSS(VSS)' in lines[i+2]:
                            hasGroundConnection = True
                        if not hasGroundConnection and not hasPowerConnection:
                            # print the line
                            print(f"Found submodule at line {i}, ", line.rstrip())
                            # Log the power connection being made
                            print(f"Adding VDD from {module} to {submodule}")
                            lines.insert(i + 1, '    .VDD(VDD), // power connection\n')    
                            # Log the ground connection being made
                            print(f"Adding VSS from {module} to {submodule}")
                            lines.insert(i + 2, '    .VSS(VSS), // ground connection\n')

            # Store the modified module to the output directory
            with open(os.path.join(outputDir, module + '.v'), 'w') as file:
                file.writelines(lines)

# Main function
def main():
    moduleDeps = parseVerilogFiles(verilogDir)
    print("Module dependencies:", moduleDeps)
    
    for baseModule in baseModules:
        findModulesNeedingPowerPins(moduleDeps, baseModule)
        # print("Modules to update with power pins:", modulesToUpdate)
        addPowerPins(modulesToUpdate, moduleDeps)

if __name__ == "__main__":
    main()
