// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`include "prim_assert.sv"

/**
 * OTBN execute block for the base instruction subset
 *
 * This ALU supports the execution of all of OTBN's base instruction subset.
 */
module otbn_alu_base
  import otbn_pkg::*;
(
  // Block is combinatorial; clk/rst are for assertions only.
  input  logic          clk_i,
  input  logic          rst_ni,

  input  alu_base_in_t  in_i,
  output alu_base_out_t out_o
);

  always_comb begin
    out_o = '{default: '0};
      unique case (in_i.op)
        AluOpAdd:
          out_o.result = in_i.operand_a + in_i.operand_b;
      endcase
    end
  end
endmodule
