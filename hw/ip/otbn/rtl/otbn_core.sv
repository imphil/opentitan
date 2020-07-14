// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`include "prim_assert.sv"

/**
 * OpenTitan Big Number Accelerator (OTBN) Core
 *
 * This module is the top-level of the OTBN processing core.
 */
module otbn_core
  import otbn_pkg::*;
#(
  // Size of the instruction memory, in bytes
  parameter int ImemSizeByte = 4096,
  // Size of the data memory, in bytes
  parameter int DmemSizeByte = 4096,

  localparam int ImemAddrWidth = prim_util_pkg::vbits(ImemSizeByte),
  localparam int DmemAddrWidth = prim_util_pkg::vbits(DmemSizeByte)
)(
  input  logic  clk_i,
  input  logic  rst_ni,

  input  logic  start_i, // start the operation
  output logic  done_o,  // operation done

  input  logic [ImemAddrWidth-1:0] start_addr_i, // start byte address in IMEM

  // Instruction memory (IMEM). Read-only.
  output logic                     imem_req_o,
  output logic [ImemAddrWidth-1:0] imem_addr_o,
  input  logic [31:0]              imem_rdata_i,
  input  logic                     imem_rvalid_i,
  input  logic [1:0]               imem_rerror_i,

  // Data memory (DMEM)
  output logic                     dmem_req_o,
  output logic                     dmem_write_o,
  output logic [DmemAddrWidth-1:0] dmem_addr_o,
  output logic [WLEN-1:0]          dmem_wdata_o,
  output logic [WLEN-1:0]          dmem_wmask_o,
  input  logic [WLEN-1:0]          dmem_rdata_i,
  input  logic                     dmem_rvalid_i,
  input  logic [1:0]               dmem_rerror_i
);

  // TODO: This is probably not the final OTBN implementation.

  // Errors (to be turned into alerts)
  assign err_o = err_alu_base | err_alu_bn | err_decode;

  // Random number
  // TODO: Hook up to RNG distribution network
  // TODO: Decide what guarantees we make for random numbers on CSRs/WSRs, and how they might or
  // might not come from the same source.
  logic [WLEN-1:0] rnd;
  assign rnd = 'd42;

  // Instruction fetch unit
  otbn_instruction_fetch #(
    .ImemSizeByte(ImemSizeByte)
  ) u_otbn_instruction_fetch (
    .clk_i,
    .rst_ni,

    // Instruction memory interface
    .imem_req_o,
    .imem_addr_o,
    .imem_rdata_i,
    .imem_rvalid_i,
    .imem_rerror_i,

    // Instruction to fetch
    .insn_fetch_req_addr_i(insn_fetch_req_addr),
    .insn_fetch_req_valid_i(insn_fetch_req_valid),

    // Fetched instruction
    .insn_fetch_resp_addr_o  (insn_addr),
    .insn_fetch_resp_valid_o (insn_data_valid),
    .insn_fetch_resp_data_o  (insn_data)
  );


  // The currently executed instruction.
  // TODO: Not really happy with the naming; insn_addr is also qualified by the insn_data_valid,
  // but insn_valid is already used below ...
  logic [ImemAddrWidth-1:0] insn_addr;
  logic insn_data_valid;
  logic [31:0] insn_data;

  logic insn_valid;
  insn_dec_base_t insn_dec_base;
  insn_dec_bignum_t insn_dec_bignum;

  insn_dec_ctrl_t insn_dec_ctrl;

  logic [4:0]   rf_base_wr_addr;
  logic         rf_base_wr_en;
  logic [31:0]  rf_base_wr_data;
  logic [4:0]   rf_base_rd_addr_a;
  logic [31:0]  rf_base_rd_data_a;
  logic [4:0]   rf_base_rd_addr_b;
  logic [31:0]  rf_base_rd_data_b;

  alu_base_in_t alu_base_in;
  alu_base_out_t alu_base_out;

  alu_bignum_in_t alu_bignum_in;
  alu_bignum_out_t alu_bignum_out;

  mac_bignum_in_t mac_bignum_in;
  mac_bignum_out_t mac_bignum_out;

  // Instruction decoder
  otbn_decoder u_otbn_decoder (
    // The decoder is combinatorial; clk and rst are only used for assertions.
    .clk_i,
    .rst_ni,

    // Instruction to decode
    .insn_data_i(insn_data),
    .insn_data_valid_i(insn_data_valid),

    // Decoded instruction
    .insn_valid_o(insn_valid),
    .insn_dec_base_o(insn_dec_base),
    .insn_dec_bignum_o(insn_dec_bignum),

    .insn_dec_ctrl_o(insn_dec_ctrl)
  );

  // Controller: coordinate between functional units, prepare their inputs (e.g. by muxing between
  // operand sources), and post-process their outputs as needed.
  otbn_controller #(
    .ImemSizeByte(ImemSizeByte),
    .DmemSizeByte(DmemSizeByte)
  ) u_otbn_controller (
    .clk_i,
    .rst_ni,

    .start_i,
    .done_o,
    .start_addr_i,

    // Next instruction selection (to instruction fetch)
    .insn_fetch_req_addr_o(insn_fetch_req_addr),
    .insn_fetch_req_valid_o(insn_fetch_req_valid),

    // Decoded instruction from decoder
    .insn_dec_base_i(insn_dec_base),
    .insn_dec_bignum_i(insn_dec_bignum),
    .insn_dec_ctrl_i(insn_dec_ctrl),

    // To/from base ALU
    .alu_base_in_o(alu_base_in),
    .alu_base_out_i(alu_base_out),

    // To/from BN ALU
    .alu_bignum_in_o(alu_bignum_in),
    .alu_bignum_out_i(alu_bignum_out),

    // To/from BN MAC
    .mac_bignum_in_o(mac_bignum_in),
    .mac_bignum_out_i(mac_bignum_out)
  );

  // Load store unit: read and write data from data memory
  otbn_lsu u_otbn_lsu (
    .clk_i,
    .rst_ni,

    // Data memory interface
    .dmem_req_o,
    .dmem_write_o,
    .dmem_addr_o,
    .dmem_wdata_o,
    .dmem_wmask_o,
    .dmem_rdata_i,
    .dmem_rvalid_i,
    .dmem_rerror_i

    // Data from base and bn execute blocks.
    // TODO: Add signals to controller
  );

  // Control and Status registers
  // 32b Control and Status Registers (CSRs), and WLEN Wide Special-Purpose Registers (WSRs)
  otbn_csrs_wdrs u_otbn_csrs_wdrs (
    .clk_i,
    .rst_ni,
    .mod_i(mod),
    .rnd_i(rnd)

    // TODO: Add signals to controller
  );

  // Base Instruction Subset =======================================================================

  // General-Purpose Register File (GPRs): 32 32b registers
  otbn_rf_base u_otbn_rf_base (
    .clk_i,
    .rst_ni,

    .wr_addr_i(rf_base_wr_addr),
    .wr_en_i(rf_base_wr_en),
    .wr_data_i(rf_base_wr_data),

    .rd_addr_a_i(rf_base_rd_addr_a),
    .rd_data_a_i(rf_base_rd_data_a),
    .rd_addr_b_i(rf_base_rd_addr_b),
    .rd_data_b_i(rf_base_rd_data_b)
  );

  otbn_alu_base u_otbn_alu_base (
    .clk_i,
    .rst_ni,

    .in_valid_i(alu_base_in_valid),
    .in_i(alu_base_in),
    .out_o(alu_base_out)
  );

  // Big Number Instruction Subset =================================================================

  // Wide Data Register file (WDRs): 32 WLEN registers
  otbn_rf_bignum u_otbn_rf_bignum (
    .clk_i,
    .rst_ni,
    .*
  );

  otbn_alu_bignum u_otbn_alu_bignum (
    .clk_i,
    .rst_ni,
    .mod_i(mod),

    .in_valid_i(alu_bignum_in_valid),
    .in_i(alu_bignum_in),

    .out_valid_o(alu_bignum_out_valid),
    .out_o(alu_bignum_out)
  );

  otbn_mac_bignum u_otbn_mac_bignum (
    .clk_i,
    .rst_ni,

    .in_valid_i(mac_bignum_in_valid),
    .in_i(mac_bignum_in),

    .out_valid_o(mac_bignum_out_valid),
    .out_o(mac_bignum_out)
  );

endmodule
