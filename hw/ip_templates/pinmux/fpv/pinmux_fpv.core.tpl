CAPI=2:
# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
name: "lowrisc:fpv:pinmux_fpv:0.1"
description: "pinmux FPV target"
filesets:
  files_formal:
    depend:
      - lowrisc:prim:all
      - lowrisc:ip:tlul
      - ${instance_vlnv("lowrisc:ip:pinmux")}
      - lowrisc:fpv:csr_assert_gen
    files:
      - vip/pinmux_assert_fpv.sv
      - tb/pinmux_bind_fpv.sv
      - tb/pinmux_fpv.sv
    file_type: systemVerilogSource

generate:
  csr_assert_gen:
    generator: csr_assert_gen
    parameters:
      spec: ../data/pinmux.hjson

targets:
  default: &default_target
    default_tool: icarus
    filesets:
      - files_formal
    generate:
      - csr_assert_gen
    toplevel: pinmux_fpv

  formal:
    <<: *default_target

  lint:
    <<: *default_target
