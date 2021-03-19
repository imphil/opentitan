CAPI=2:
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
name: ${instance_vlnv("lowrisc:dv:flash_ctrl_sim:0.1")}
description: "FLASH_CTRL DV sim target"
filesets:
  files_rtl:
    depend:
      - lowrisc:ip:tlul
      - lowrisc:constants:top_pkg
      - ${instance_vlnv("lowrisc:ip:flash_ctrl_pkg")}
      - ${instance_vlnv("lowrisc:ip:flash_ctrl")}
    files:
      - tb/flash_ctrl_wrapper.sv
    file_type: systemVerilogSource

  files_dv:
    depend:
      - lowrisc:dv:flash_ctrl_test
      - lowrisc:dv:flash_ctrl_sva
    files:
      - tb/tb.sv
    file_type: systemVerilogSource

targets:
  default: &default_target
    toplevel: tb
    filesets:
      - files_rtl
      - files_dv

  sim:
    <<: *default_target
    default_tool: vcs

  lint:
    <<: *default_target
