// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`include "prim_assert.sv"

/**
 * ALU for Big Number operations
 *
 * The ALU performs bitwise, arithmetic, and shift operations.
 */
module otbn_alu_bignum
  import otbn_pkg::*;
(
  input logic clk_i,
  input logic rst_ni,

  input logic [WLEN-1:0] a_i,
  input logic [WLEN-1:0] b_i,
  input logic [11:0] imm_i,

  input logic       shift_left_i,
  input logic [7:0] shift_amt_i,

  input logic imm_sel_i,
  input logic sub_en_i,
  input logic shift_en_i,
  input logic mod_i,
);

endmodule
