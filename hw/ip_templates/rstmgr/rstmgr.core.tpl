CAPI=2:
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
name: ${instance_vlnv("lowrisc:ip:rstmgr:0.1")}
description: "Reset manager"

filesets:
  files_rtl:
    depend:
      - lowrisc:ip:tlul
      - lowrisc:prim:clock_mux2
      - lowrisc:prim:lc_sync
      - ${instance_vlnv("lowrisc:ip:rstmgr_pkg:0.1")}
      - ${instance_vlnv("lowrisc:ip:rstmgr_reg:0.1")}
      - lowrisc:ip_interfaces:pwrmgr_reg
      - lowrisc:ip:pwrmgr_pkg
      - lowrisc:ip_interfaces:alert_handler
      - lowrisc:ibex:ibex_pkg
      - "fileset_topgen ? (lowrisc:systems:topgen)"
      # TODO: Likely we're missing the power manager here and other things
    files:
      - rtl/rstmgr_ctrl.sv
      - rtl/rstmgr_por.sv
      - rtl/rstmgr_crash_info.sv
      - rtl/rstmgr.sv
    file_type: systemVerilogSource

  files_verilator_waiver:
    depend:
      # common waivers
      - lowrisc:lint:common
      - lowrisc:lint:comportable
    files:
    file_type: vlt

  files_ascentlint_waiver:
    depend:
      # common waivers
      - lowrisc:lint:common
      - lowrisc:lint:comportable
    files:
      - lint/rstmgr.waiver
    file_type: waiver

parameters:
  SYNTHESIS:
    datatype: bool
    paramtype: vlogdefine


targets:
  default: &default_target
    filesets:
      - tool_verilator  ? (files_verilator_waiver)
      - tool_ascentlint ? (files_ascentlint_waiver)
      - files_rtl
    toplevel: rstmgr

  lint:
    <<: *default_target
    default_tool: verilator
    parameters:
      - SYNTHESIS=true
    tools:
      verilator:
        mode: lint-only
        verilator_options:
          - "-Wall"
