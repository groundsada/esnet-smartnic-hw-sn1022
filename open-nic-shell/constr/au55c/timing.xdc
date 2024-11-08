# *************************************************************************
#
# Copyright 2020 Xilinx, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# *************************************************************************
create_clock -period 10.000 -name pcie_refclk [get_ports pcie_refclk_p]

set_false_path -through [get_ports pcie_rstn]

foreach axis_aclk [get_clocks -of_object [get_nets axis_aclk*]] {
    foreach cmac_clk [get_clocks -of_object [get_nets cmac_clk*]] {
        set_max_delay -datapath_only -from $axis_aclk -to $cmac_clk 4.000
        set_max_delay -datapath_only -from $cmac_clk -to $axis_aclk 3.103 
    }
}

create_pblock pblock_cmac_subsystem
add_cells_to_pblock [get_pblocks pblock_cmac_subsystem] [get_cells -quiet {cmac_port*.cmac_subsystem_inst}]
resize_pblock [get_pblocks pblock_cmac_subsystem] -add {CLOCKREGION_X0Y5:CLOCKREGION_X3Y7}

create_pblock pblock_packet_adapter
add_cells_to_pblock [get_pblocks pblock_packet_adapter] [get_cells -quiet {cmac_port*.packet_adapter_inst}]
resize_pblock [get_pblocks pblock_packet_adapter] -add {SLR1}

create_pblock pblock_qdma_subsystem
add_cells_to_pblock [get_pblocks pblock_qdma_subsystem] [get_cells -quiet {qdma_if*.qdma_subsystem_inst}]
resize_pblock [get_pblocks pblock_qdma_subsystem] -add {CLOCKREGION_X4Y0:CLOCKREGION_X7Y3}
