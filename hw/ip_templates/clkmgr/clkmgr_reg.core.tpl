CAPI=2:
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
name: ${instance_vlnv("lowrisc:ip:clkmgr_reg:0.1")}
description: "Clock Manager Package"

filesets:
  files_rtl:
    depend:
      - lowrisc:ip:tlul
    files:
      - rtl/clkmgr_reg_pkg.sv
      - rtl/clkmgr_reg_top.sv
    file_type: systemVerilogSource

targets:
  default:
    filesets:
      - files_rtl
