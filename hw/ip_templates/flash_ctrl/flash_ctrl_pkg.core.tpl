CAPI=2:
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
name: ${instance_vlnv("lowrisc:ip:flash_ctrl_pkg:0.1")}
provide:
  # TODO: Ensure that the API provided by the auto-generated reg packages is
  # stable.
  - lowrisc:ip_interfaces:flash_ctrl_pkg
description: "Flash Package"

filesets:
  files_rtl:
    depend:
      - lowrisc:constants:top_pkg
      - lowrisc:prim:util
      - lowrisc:ip:lc_ctrl_pkg
      - lowrisc:ip:pwrmgr_pkg
      - lowrisc:ip:jtag_pkg
      - lowrisc:ip:edn_pkg
      - "fileset_topgen ? (lowrisc:systems:topgen)"
    files:
      - rtl/flash_ctrl_reg_pkg.sv
      - rtl/flash_ctrl_pkg.sv
      - rtl/flash_phy_pkg.sv
    file_type: systemVerilogSource

targets:
  default:
    filesets:
      - files_rtl
