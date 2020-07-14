// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`include "prim_assert.sv"

/**
 * OTBN Instruction Fetch Unit
 *
 * Fetch an instruction from the instruction memory.
 */
module otbn_instruction_fetch
#(
  parameter int ImemSizeByte = 4096,

  localparam int ImemAddrWidth = prim_util_pkg::vbits(ImemSizeByte)
) (
  input logic clk_i,
  input logic rst_ni,

  // Instruction memory (IMEM) interface. Read-only.
  output logic                     imem_req_o,
  output logic [DmemAddrWidth-1:0] imem_addr_o,
  input  logic [WLEN-1:0]          imem_rdata_i,
  input  logic                     imem_rvalid_i,
  input  logic [1:0]               imem_rerror_i, // Bit1: Uncorrectable, Bit0: Correctable
);

endmodule
