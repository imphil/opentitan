// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * OTBN Special Purpose Registers: 32b CSRs, and WLEN WSRs
 */
module otbn_csrs_wdrs
  import otbn_pkg::*;
(
  input logic             clk_i,
  input logic             rst_ni,

  // CSR interface to registers (SRAM like)
  input  logic            csr_req_i,
  input  logic            csr_write_i,
  input  csr_num_e        csr_num_i,
  input  logic [31:0]     csr_wdata_i,
  output logic [31:0]     csr_rdata_o, // Read data. Data is returned one cycle after req_i is high.

  // WDR interface to registers (SRAM like)
  input  logic            wdr_req_i,
  input  logic            wdr_write_i,
  input  wdr_num_e        wdr_num_i,
  input  logic [WLEN-1:0] wdr_wdata_i,
  output logic [WLEN-1:0] wdr_rdata_o, // Read data. Data is returned one cycle after req_i is high.

  // Random number (read-only through CSRs/WSRs)
  input  logic [WLEN-1:0] rnd_i,

  // Flag data (read/write through a CSR, stored in the BN MAC module)
  input  flag_e           flag_rdata_i [NFlagGroups],
  output logic            flag_wdata_o,
  output flag_e           flag_wr [NFlagGroups],

  // Modulus (stored within this module)
  output logic [WLEN-1:0] mod_o,
  input  [WLEN-1:0]       mod_i,
  input                   mod_valid_i
);

  logic [WLEN-1:0] mod;



endmodule
