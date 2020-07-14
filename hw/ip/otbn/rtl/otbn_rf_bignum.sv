// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * WLEN bit Wide Data Registers (WDRs)
 *
 * Features:
 * - 2 read ports
 * - 1 write port with half-word select
 */
module otbn_rf_bn
  import otbn_pkg::*;
#(
  localparam Aw = $clog2(NWdr)
) (
  input logic             clk_i,
  input logic             rst_ni,

  input logic  [4:0]      wr_addr_i,
  input logic  [1:0]      wr_en_i,
  input logic  [WLEN-1:0] wr_data_i,

  input logic  [4:0]      rd_addr_a_i,
  output logic [WLEN-1:0] rd_data_a_o,
  input logic  [4:0]      rd_addr_b_i,
  output logic [WLEN-1:0] rd_data_b_o
);

endmodule
