// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`include "prim_assert.sv"

/**
 * OTBN Controller
 */
module otbn_controller
  import otbn_pkg::*;
#(
  // Size of the instruction memory, in bytes
  parameter int ImemSizeByte = 4096,
  // Size of the data memory, in bytes
  parameter int DmemSizeByte = 4096,

  localparam int ImemAddrWidth = prim_util_pkg::vbits(ImemSizeByte),
  localparam int DmemAddrWidth = prim_util_pkg::vbits(DmemSizeByte)
) (
  input  logic  clk_i,
  input  logic  rst_ni,

  input  logic                     start_i, // start the operation
  output logic                     done_o,  // operation done
  input  logic [ImemAddrWidth-1:0] start_addr_i,

  // Next instruction selection (to instruction fetch)
  output                     insn_fetch_req_valid_o
  output [ImemAddrWidth-1:0] insn_fetch_req_addr_o,

  // Decoded instruction
  output [ImemAddrWidth-1:0] insn_addr_i,
  input  logic               insn_valid_i,

  // Decoded instruction data, matching the "Decoding" section of the specification.
  input insn_dec_base_t       insn_dec_base_i,
  input insn_dec_bignum_t     insn_dec_bignum_i,
  input insn_dec_ctrl_t       insn_dec_ctrl_i,

  // Base register file
  output logic [4:0]   rf_base_wr_addr_o,
  output logic         rf_base_wr_en_o,
  output logic [31:0]  rf_base_wr_data_o,

  output logic [4:0]   rf_base_rd_addr_a_o,
  input  logic [31:0]  rf_base_rd_data_a_i,

  output logic [4:0]   rf_base_rd_addr_b_o,
  input  logic [31:0]  rf_base_rd_data_b_i,

  // Execution units
  output alu_base_in_t  alu_base_in_o,
  input  alu_base_out_t alu_base_out_i,

  output alu_bignum_in_t  alu_bignum_in_o,
  input  alu_bignum_out_t alu_bignum_out_i,

  output mac_bignum_in_t  mac_bignum_in_o,
  input  mac_bignum_out_t mac_bignum_out_i,
);

  assign done_o = (insn_valid_i && insn_op_i == InsnEcall) ? 1'b1 : 1'b0;

  // Next fetch address
  always_comb begin
    if (start_i) begin
      insn_fetch_req_addr_o = start_addr_i;
    end else begin
      insn_fetch_req_addr_o = insn_addr_i + 'd4;
    end
    // TODO: Jumps/branches
  end

  assign rf_base_rd_addr_a_i = insn_dec_ctrl_i.a;
  assign rf_base_rd_addr_b_i = insn_dec_ctrl_i.b;

  // Base ALU Operand A MUX
  always_comb begin
    unique case (insn_dec_ctrl_i.op_a_sel)
      OpASelRegister:
        alu_base_in_o.operand_a = rf_base_rd_data_a_i;
    endcase
  end

  // Base ALU Operand B MUX
  always_comb begin
    unique case (insn_dec_ctrl_i.op_a_sel)
      OpBSelRegister:
        alu_base_in_o.operand_b = rf_base_rd_data_b_i;
      OpBSelImmediate:
        alu_base_in_o.operand_b = insn_dec_ctrl_i.i;
    endcase
  end

  assign alu_base_in_o.op = insn_dec_ctrl_i.alu_op;

endmodule
