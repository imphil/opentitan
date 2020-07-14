// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
package otbn_pkg;

  // Global Constants ==============================================================================

  // Data path width for BN (wide) instructions, in bits.
  parameter int WLEN = 256;

  // Number of flag groups
  parameter int NFlagGroups = 2;

  // Number of General Purpose Registers (GPRs)
  parameter int NGpr = 32;
  localparam GprAw = $clog2(NGpr);

  // Number of Wide Data Registers (WDRs)
  parameter int NWdr = 32;
  localparam WdrAw = $clog2(NWdr);


  // Toplevel constants ============================================================================

  // Alerts
  parameter int                   NumAlerts = 3;
  parameter logic [NumAlerts-1:0] AlertAsyncOn = {NumAlerts{1'b1}};

  parameter int AlertImemUncorrectable = 0;
  parameter int AlertDmemUncorrectable = 1;
  parameter int AlertRegUncorrectable = 2;

  // Error codes
  typedef enum bit [31:0] {
    ErrCodeNoError = 32'h 0000_0000
  } err_code_e;

  // Constants =====================================================================================

  typedef enum bit {
    InsnSubsetBase = 1'b0,  // Base (RV32/Narrow) Instruction Subset
    InsnSubsetBignum = 1'b1 // Big Number (BN/Wide) Instruction Subset
  } insn_subset_e;

  typedef enum bit [1:0] {
    FlagCarry = 2'd0,
    FlagLsb   = 2'd1,
    FlagMsb   = 2'd2,
    FlagZero  = 2'd3
  } flag_e;

  typedef enum bit {
    ShiftTypeLSL = 1'b0,
    ShiftTypeLSR = 1'b1
  } shift_type_e;

  typedef enum bit [1:0] {
    WritebackVariantNone     = 2'b00,
    WritebackVariantWriteout = 1'b01,
    WritebackVariantShiftout = 1'b10 // TODO: Check insns.yml, it doesn't specify bit 30?
  } writeback_variant_e;

  // Decoded instruction components, with signals matching the "Decoding" section of the
  // specification.
  // TODO: The variable names are rather short, especially "i" is confusing. Think about renaming.

  typedef struct packed {
    logic [4:0] d,  // Destination register
    logic [4:0] a,  // First source register
    logic [4:0] b,  // Second source register
    logic [31:0] i  // Immediate
  } insn_dec_base_t;

  typedef struct packed {
    logic [4:0] d,                     // Destination register
    logic [4:0] a,                     // First source register
    logic [4:0] b,                     // Second source register
    logic [vbits(NFlagGroups)-1:0] fg, // Flag Group
    logic [WLEN-1:0] i,                // Immediate

    logic shift_type_e st,             // Shift Type
    logic [4:0] sb                     // Shift Bytes

    // BN.MULQACC only
    logic d_hwsel,                                // Half-word select for register d
    logic [1:0] a_qwsel,                          // Quarter-word select for register a
    logic [1:0] b_qwsel                           // Quarter-word select for register b
    logic writeback_variant_e writeback_variant,  // Writeback variant
  } insn_dec_bignum_t;

  // Operand a source selection
  typedef enum logic[1:0] {
    OpASelRegister,
    OpASelImmediate
  } op_a_sel_e;

  // Operand b source selection
  typedef enum logic {
    OpBSelRegister,
    OpBSelImmediate
  } op_b_sel_e;

  // Control signals from decoder to controller: additional information about the decoded
  // instruction influencing the operation.
  typedef struct packed {
    insn_subset_e subset,
    op_a_sel_e    op_a_sel,
    op_b_sel_e    op_b_sel,
    alu_op_e      alu_op
  } insn_dec_ctrl_t;

  typedef struct packed {
    alu_op_e op,
    logic [31:0] operand_a,
    logic [31:0] operand_b
  } alu_base_in_t;

  typedef struct packed {
    logic [31:0] result,
    logic comparision_result
  } alu_base_out_t;

  typedef struct packed {
    alu_op_e op,
    logic [WLEN-1:0] operand_a,
    logic [WLEN-1:0] operand_b,

    logic shift_type_e st,  // Shift Type
    logic [4:0] sb          // Shift Bytes
    logic [WLEN-1:0] mod,
    flag_e flags [NFlagGroups]
  } alu_bignum_in_t;

  typedef struct packed {
    logic [WLEN-1:0] result,
    logic comparision_result,
    flag_e flags [NFlagGroups]
  } alu_bignum_out_t;

  typedef enum bit [3:0] {
    AluOpAdd,
    AluOpSub,

    AluOpXor,
    AluOpOr,
    AluOpAnd,
    AluOpNot,

    AluOpEq,
    AluOpNeq,
  } alu_op_e;

  // Instructions
  typedef enum {
    InsnOpAdd,
    InsnOpEcall,
    InsnOpBnMulqacc
    // TODO: Extend
  } insn_op_t;

  // Control and Status Registers (CSRs)
  parameter int CsrNumWidth = 12;
  typedef enum bit [CsrNumWidth-1:0] {
    CsrFlags = 12'd7C0,
    CsrMod0  = 12'd7D0,
    CsrMod1  = 12'd7D1,
    CsrMod2  = 12'd7D2,
    CsrMod3  = 12'd7D3,
    CsrMod4  = 12'd7D4,
    CsrMod5  = 12'd7D5,
    CsrMod6  = 12'd7D6,
    CsrMod7  = 12'd7D7,
    CsrRnd   = 12'dFC0,
  } csr_e;


  // Wide Special Purpose Registers (WSRs)
  parameter int NWsr = 3; // Number of WSRs
  parameter int WsrNumWidth = $clog2(NWsr);
  typedef enum bit [WsrNumWidth-1:0] {
    WsrMod = 'd0,
    WsrRnd = 'd1,
    WsrAcc = 'd2
  } wsr_e;
  `ASSERT_INIT(WsrESizeMatchesParameter_A, $bits(wsr_e) == WdrNumWidth)

endpackage
