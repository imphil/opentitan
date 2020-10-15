// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

`include "prim_assert.sv"

/**
 * OpenTitan Big Number Accelerator (OTBN)
 */
module otbn
  import prim_alert_pkg::*;
  import otbn_pkg::*;
  import otbn_reg_pkg::*;
#(
  parameter regfile_e             RegFile      = RegFileFF,
  parameter logic [NumAlerts-1:0] AlertAsyncOn = {NumAlerts{1'b1}}
) (
  input clk_i,
  input rst_ni,

  input  tlul_pkg::tl_h2d_t tl_i,
  output tlul_pkg::tl_d2h_t tl_o,

  // Inter-module signals
  output logic idle_o,

  // Interrupts
  output logic intr_done_o,
  output logic intr_err_o,

  // Alerts
  input  prim_alert_pkg::alert_rx_t [NumAlerts-1:0] alert_rx_i,
  output prim_alert_pkg::alert_tx_t [NumAlerts-1:0] alert_tx_o

  // CSRNG interface
  // TODO: Needs to be connected to RNG distribution network (#2638)
);

  import prim_util_pkg::vbits;

  // The OTBN_*_SIZE parameters are auto-generated by regtool and come from the
  // bus window sizes; they are given in bytes.
  localparam int ImemSizeByte = otbn_reg_pkg::OTBN_IMEM_SIZE;
  localparam int DmemSizeByte = otbn_reg_pkg::OTBN_DMEM_SIZE;

  localparam int ImemAddrWidth = vbits(ImemSizeByte);
  localparam int DmemAddrWidth = vbits(DmemSizeByte);

`ifdef OTBN_MODEL
  localparam int OTBNModel = 1;
`else
  localparam int OTBNModel = 0;
`endif

  logic start;
  logic busy_d, busy_q;
  logic done;

  logic        err_valid;
  logic [31:0] err_code;

  logic [ImemAddrWidth-1:0] start_addr;

  otbn_reg2hw_t reg2hw;
  otbn_hw2reg_t hw2reg;

  // Bus device windows, as specified in otbn.hjson
  typedef enum int {
    TlWinImem = 0,
    TlWinDmem = 1
  } tl_win_e;

  tlul_pkg::tl_h2d_t tl_win_h2d [2];
  tlul_pkg::tl_d2h_t tl_win_d2h [2];


  // Inter-module signals ======================================================

  // TODO: Better define what "idle" means -- only the core, or also the
  // register interface?
  assign idle_o = ~busy_q | ~start;


  // Interrupts ================================================================

  prim_intr_hw #(
    .Width(1)
  ) u_intr_hw_done (
    .clk_i,
    .rst_ni,
    .event_intr_i           (done),
    .reg2hw_intr_enable_q_i (reg2hw.intr_enable.done.q),
    .reg2hw_intr_test_q_i   (reg2hw.intr_test.done.q),
    .reg2hw_intr_test_qe_i  (reg2hw.intr_test.done.qe),
    .reg2hw_intr_state_q_i  (reg2hw.intr_state.done.q),
    .hw2reg_intr_state_de_o (hw2reg.intr_state.done.de),
    .hw2reg_intr_state_d_o  (hw2reg.intr_state.done.d),
    .intr_o                 (intr_done_o)
  );
  prim_intr_hw #(
    .Width(1)
  ) u_intr_hw_err (
    .clk_i,
    .rst_ni,
    .event_intr_i           (err_valid),
    .reg2hw_intr_enable_q_i (reg2hw.intr_enable.err.q),
    .reg2hw_intr_test_q_i   (reg2hw.intr_test.err.q),
    .reg2hw_intr_test_qe_i  (reg2hw.intr_test.err.qe),
    .reg2hw_intr_state_q_i  (reg2hw.intr_state.err.q),
    .hw2reg_intr_state_de_o (hw2reg.intr_state.err.de),
    .hw2reg_intr_state_d_o  (hw2reg.intr_state.err.d),
    .intr_o                 (intr_err_o)
  );


  // Registers =================================================================

  otbn_reg_top u_reg (
    .clk_i,
    .rst_ni,
    .tl_i,
    .tl_o,
    .tl_win_o (tl_win_h2d),
    .tl_win_i (tl_win_d2h),

    .reg2hw,
    .hw2reg,

    .devmode_i (1'b1)
  );

  // CMD register
  assign start = reg2hw.cmd.start.qe & reg2hw.cmd.start.q;

  // STATUS register
  assign hw2reg.status.busy.d = busy_q;
  assign hw2reg.status.dummy.d = 1'b0;

  // ERR_CODE register
  assign hw2reg.err_code.de = err_valid;
  assign hw2reg.err_code.d  = err_code;

  // START_ADDR register
  assign start_addr = reg2hw.start_addr.q[ImemAddrWidth-1:0];

  // Errors ====================================================================

  // err_valid goes high if there is a new error this cycle. This causes the
  // register block to take a new error code (stored as ERR_CODE) and triggers
  // an interrupt. To ensure software on the host CPU only sees the first event
  // in a series, err_valid is squashed if there is an existing error. Software
  // should read the ERR_CODE register before clearing the interrupt to avoid
  // race conditions.
  assign err_valid = ~reg2hw.intr_state.err.q &
    (1'b0); // TODO: OR error signals here.

  always_comb begin
    err_code = ErrCodeNoError;
    unique case (1'b1)
      // TODO: Add more errors here.

      default: begin
        err_code = ErrCodeNoError;
      end
    endcase
  end

  // Instruction Memory (IMEM) =================================================

  localparam int ImemSizeWords = ImemSizeByte / 4;
  localparam int ImemIndexWidth = vbits(ImemSizeWords);

  // Access select to IMEM: core (1), or bus (0)
  logic imem_access_core;

  logic imem_req;
  logic imem_write;
  logic [ImemIndexWidth-1:0] imem_index;
  logic [31:0] imem_wdata;
  logic [31:0] imem_wmask;
  logic [31:0] imem_rdata;
  logic imem_rvalid;
  logic [1:0] imem_rerror;

  logic imem_req_core;
  logic imem_write_core;
  logic [ImemIndexWidth-1:0] imem_index_core;
  logic [31:0] imem_wdata_core;
  logic [31:0] imem_rdata_core;
  logic imem_rvalid_core;
  logic [1:0] imem_rerror_core;

  logic imem_req_bus;
  logic imem_write_bus;
  logic [ImemIndexWidth-1:0] imem_index_bus;
  logic [31:0] imem_wdata_bus;
  logic [31:0] imem_wmask_bus;
  logic [31:0] imem_rdata_bus;
  logic imem_rvalid_bus;
  logic [1:0] imem_rerror_bus;

  logic [ImemAddrWidth-1:0] imem_addr_core;
  assign imem_index_core = imem_addr_core[ImemAddrWidth-1:2];

  logic [1:0] unused_imem_addr_core_wordbits;
  assign unused_imem_addr_core_wordbits = imem_addr_core[1:0];

  prim_ram_1p_adv #(
    .Width           (32),
    .Depth           (ImemSizeWords),
    .DataBitsPerMask (32), // Write masks are not supported.
    .CfgW            (8)
  ) u_imem (
    .clk_i,
    .rst_ni,
    .req_i    (imem_req),
    .write_i  (imem_write),
    .addr_i   (imem_index),
    .wdata_i  (imem_wdata),
    .wmask_i  (imem_wmask),
    .rdata_o  (imem_rdata),
    .rvalid_o (imem_rvalid),
    .rerror_o (imem_rerror),
    .cfg_i    ('0)
  );

  // IMEM access from main TL-UL bus
  logic imem_gnt_bus;
  assign imem_gnt_bus = imem_req_bus & ~imem_access_core;

  tlul_adapter_sram #(
    .SramAw      (ImemIndexWidth),
    .SramDw      (32),
    .Outstanding (1),
    .ByteAccess  (0),
    .ErrOnRead   (0)
  ) u_tlul_adapter_sram_imem (
    .clk_i,
    .rst_ni,
    .tl_i   (tl_win_h2d[TlWinImem]),
    .tl_o   (tl_win_d2h[TlWinImem]),

    .req_o    (imem_req_bus   ),
    .gnt_i    (imem_gnt_bus   ),
    .we_o     (imem_write_bus ),
    .addr_o   (imem_index_bus ),
    .wdata_o  (imem_wdata_bus ),
    .wmask_o  (imem_wmask_bus ),
    .rdata_i  (imem_rdata_bus ),
    .rvalid_i (imem_rvalid_bus),
    .rerror_i (imem_rerror_bus)
  );

  // Mux core and bus access into IMEM
  assign imem_access_core = busy_q;

  assign imem_req   = imem_access_core ? imem_req_core   : imem_req_bus;
  assign imem_write = imem_access_core ? imem_write_core : imem_write_bus;
  assign imem_index = imem_access_core ? imem_index_core : imem_index_bus;
  assign imem_wdata = imem_access_core ? imem_wdata_core : imem_wdata_bus;

  // The instruction memory only supports 32b word writes, so we hardcode its
  // wmask here.
  //
  // Since this could cause confusion if the bus tried to do a partial write
  // (which wasn't caught in the TLUL adapter for some reason), we assert that
  // the wmask signal from the bus is indeed '1 when it requests a write. We
  // don't have the corresponding check for writes from the core because the
  // core cannot perform writes (and has no imem_wmask_o port).
  assign imem_wmask = 32'hFFFFFFFF;
  `ASSERT(ImemWmaskBusIsFullWord_A,
      imem_req_bus && imem_write_bus |-> imem_wmask_bus == 32'hFFFFFFFF)

  // Explicitly tie off bus interface during core operation to avoid leaking
  // the currently executed instruction from IMEM through the bus
  // unintentionally.
  assign imem_rdata_bus  = !imem_access_core ? imem_rdata : 32'b0;
  assign imem_rdata_core = imem_rdata;

  assign imem_rvalid_bus  = !imem_access_core ? imem_rvalid : 1'b0;
  assign imem_rvalid_core = imem_access_core ? imem_rvalid : 1'b0;

  // Since rerror depends on rvalid we could save this mux, but could
  // potentially leak rerror to the bus. Err on the side of caution.
  assign imem_rerror_bus  = !imem_access_core ? imem_rerror : 2'b00;
  assign imem_rerror_core = imem_rerror;


  // Data Memory (DMEM) ========================================================

  localparam int DmemSizeWords = DmemSizeByte / (WLEN / 8);
  localparam int DmemIndexWidth = vbits(DmemSizeWords);

  // Access select to DMEM: core (1), or bus (0)
  logic dmem_access_core;

  logic dmem_req;
  logic dmem_write;
  logic [DmemIndexWidth-1:0] dmem_index;
  logic [WLEN-1:0] dmem_wdata;
  logic [WLEN-1:0] dmem_wmask;
  logic [WLEN-1:0] dmem_rdata;
  logic dmem_rvalid;
  logic [1:0] dmem_rerror;

  logic dmem_req_core;
  logic dmem_write_core;
  logic [DmemIndexWidth-1:0] dmem_index_core;
  logic [WLEN-1:0] dmem_wdata_core;
  logic [WLEN-1:0] dmem_wmask_core;
  logic [WLEN-1:0] dmem_rdata_core;
  logic dmem_rvalid_core;
  logic [1:0] dmem_rerror_core;

  logic dmem_req_bus;
  logic dmem_write_bus;
  logic [DmemIndexWidth-1:0] dmem_index_bus;
  logic [WLEN-1:0] dmem_wdata_bus;
  logic [WLEN-1:0] dmem_wmask_bus;
  logic [WLEN-1:0] dmem_rdata_bus;
  logic dmem_rvalid_bus;
  logic [1:0] dmem_rerror_bus;

  logic [DmemAddrWidth-1:0] dmem_addr_core;
  assign dmem_index_core = dmem_addr_core[DmemAddrWidth-1:DmemAddrWidth-DmemIndexWidth];

  prim_ram_1p_adv #(
    .Width           (WLEN),
    .Depth           (DmemSizeWords),
    .DataBitsPerMask (32), // 32b write masks for 32b word writes from bus
    .CfgW            (8)
  ) u_dmem (
    .clk_i,
    .rst_ni,
    .req_i    (dmem_req),
    .write_i  (dmem_write),
    .addr_i   (dmem_index),
    .wdata_i  (dmem_wdata),
    .wmask_i  (dmem_wmask),
    .rdata_o  (dmem_rdata),
    .rvalid_o (dmem_rvalid),
    .rerror_o (dmem_rerror),
    .cfg_i    ('0)
  );

  // DMEM access from main TL-UL bus
  logic dmem_gnt_bus;
  assign dmem_gnt_bus = dmem_req_bus & ~dmem_access_core;

  tlul_adapter_sram #(
    .SramAw      (DmemIndexWidth),
    .SramDw      (WLEN),
    .Outstanding (1),
    .ByteAccess  (0),
    .ErrOnRead   (0)
  ) u_tlul_adapter_sram_dmem (
    .clk_i,
    .rst_ni,

    .tl_i     (tl_win_h2d[TlWinDmem]),
    .tl_o     (tl_win_d2h[TlWinDmem]),

    .req_o    (dmem_req_bus   ),
    .gnt_i    (dmem_gnt_bus   ),
    .we_o     (dmem_write_bus ),
    .addr_o   (dmem_index_bus ),
    .wdata_o  (dmem_wdata_bus ),
    .wmask_o  (dmem_wmask_bus ),
    .rdata_i  (dmem_rdata_bus ),
    .rvalid_i (dmem_rvalid_bus),
    .rerror_i (dmem_rerror_bus)
  );

  // Mux core and bus access into dmem
  assign dmem_access_core = busy_q;

  assign dmem_req   = dmem_access_core ? dmem_req_core   : dmem_req_bus;
  assign dmem_write = dmem_access_core ? dmem_write_core : dmem_write_bus;
  assign dmem_wmask = dmem_access_core ? dmem_wmask_core : dmem_wmask_bus;
  assign dmem_index = dmem_access_core ? dmem_index_core : dmem_index_bus;
  assign dmem_wdata = dmem_access_core ? dmem_wdata_core : dmem_wdata_bus;

  // Explicitly tie off bus interface during core operation to avoid leaking
  // DMEM data through the bus unintentionally.
  assign dmem_rdata_bus  = !dmem_access_core ? dmem_rdata : '0;
  assign dmem_rdata_core = dmem_rdata;

  assign dmem_rvalid_bus  = !dmem_access_core ? dmem_rvalid : 1'b0;
  assign dmem_rvalid_core = dmem_access_core  ? dmem_rvalid : 1'b0;

  // Since rerror depends on rvalid we could save this mux, but could
  // potentially leak rerror to the bus. Err on the side of caution.
  assign dmem_rerror_bus  = !dmem_access_core ? dmem_rerror : 2'b00;
  assign dmem_rerror_core = dmem_rerror;


  // Alerts ====================================================================

  logic [NumAlerts-1:0] alerts;
  assign alerts[AlertImemUncorrectable] = imem_rerror[1];
  assign alerts[AlertDmemUncorrectable] = dmem_rerror[1];
  assign alerts[AlertRegUncorrectable] = 1'b0; // TODO: Implement
  for (genvar i = 0; i < NumAlerts; i++) begin: gen_alert_tx
    prim_alert_sender #(
      .AsyncOn(AlertAsyncOn[i])
    ) i_prim_alert_sender (
      .clk_i,
      .rst_ni,
      .alert_req_i (alerts[i]    ),
      .alert_ack_o (             ),
      .alert_rx_i  (alert_rx_i[i]),
      .alert_tx_o  (alert_tx_o[i])
    );
  end


  // OTBN Core =================================================================

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      busy_q <= 1'b0;
    end else begin
      busy_q <= busy_d;
    end
  end
  assign busy_d = (busy_q | start) & ~done;

  if (OTBNModel) begin : gen_impl_model
    localparam ImemScope = "..u_imem.u_mem.gen_generic.u_impl_generic";
    localparam DmemScope = "..u_dmem.u_mem.gen_generic.u_impl_generic";

    otbn_core_model #(
      .DmemSizeByte(DmemSizeByte),
      .ImemSizeByte(ImemSizeByte),
      .DmemScope(DmemScope),
      .ImemScope(ImemScope),
      .DesignScope("")
    ) u_otbn_core_model (
      .clk_i,
      .rst_ni,

      .start_i (start),
      .done_o  (done),

      .start_addr_i  (start_addr),

      .err_o ()
    );
  end else begin : gen_impl_rtl
    otbn_core #(
      .RegFile(RegFile),
      .DmemSizeByte(DmemSizeByte),
      .ImemSizeByte(ImemSizeByte)
    ) u_otbn_core (
      .clk_i,
      .rst_ni,

      .start_i (start),
      .done_o  (done),

      .start_addr_i  (start_addr),

      .imem_req_o    (imem_req_core),
      .imem_addr_o   (imem_addr_core),
      .imem_wdata_o  (imem_wdata_core),
      .imem_rdata_i  (imem_rdata_core),
      .imem_rvalid_i (imem_rvalid_core),
      .imem_rerror_i (imem_rerror_core),

      .dmem_req_o    (dmem_req_core),
      .dmem_write_o  (dmem_write_core),
      .dmem_addr_o   (dmem_addr_core),
      .dmem_wdata_o  (dmem_wdata_core),
      .dmem_wmask_o  (dmem_wmask_core),
      .dmem_rdata_i  (dmem_rdata_core),
      .dmem_rvalid_i (dmem_rvalid_core),
      .dmem_rerror_i (dmem_rerror_core)
    );
  end

  // The core can never signal a write to IMEM
  assign imem_write_core = 1'b0;

  // LFSR ======================================================================

  // TODO: Potentially insert local LFSR, or use output from RNG distribution
  // network directly, depending on availability. Revisit once CSRNG interface
  // is known (#2638).


  // Asserts ===================================================================

  // All outputs should be known value after reset
  `ASSERT_KNOWN(TlODValidKnown_A, tl_o.d_valid)
  `ASSERT_KNOWN(TlOAReadyKnown_A, tl_o.a_ready)
  `ASSERT_KNOWN(IntrDoneOKnown_A, intr_done_o)
  `ASSERT_KNOWN(IntrErrOKnown_A, intr_err_o)
  `ASSERT_KNOWN(AlertTxOKnown_A, alert_tx_o)
  `ASSERT_KNOWN(IdleOKnown_A, idle_o)

endmodule
