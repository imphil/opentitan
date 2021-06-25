// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// tb__alert_handler_connect.sv is auto-generated by `topgen.py` tool

assign alert_if[0].alert_tx = `CHIP_HIER.u_uart0.alert_tx_o[0];
assign alert_if[1].alert_tx = `CHIP_HIER.u_uart1.alert_tx_o[0];
assign alert_if[2].alert_tx = `CHIP_HIER.u_uart2.alert_tx_o[0];
assign alert_if[3].alert_tx = `CHIP_HIER.u_uart3.alert_tx_o[0];
assign alert_if[4].alert_tx = `CHIP_HIER.u_gpio.alert_tx_o[0];
assign alert_if[5].alert_tx = `CHIP_HIER.u_spi_device.alert_tx_o[0];
assign alert_if[6].alert_tx = `CHIP_HIER.u_spi_host0.alert_tx_o[0];
assign alert_if[7].alert_tx = `CHIP_HIER.u_spi_host1.alert_tx_o[0];
assign alert_if[8].alert_tx = `CHIP_HIER.u_i2c0.alert_tx_o[0];
assign alert_if[9].alert_tx = `CHIP_HIER.u_i2c1.alert_tx_o[0];
assign alert_if[10].alert_tx = `CHIP_HIER.u_i2c2.alert_tx_o[0];
assign alert_if[11].alert_tx = `CHIP_HIER.u_pattgen.alert_tx_o[0];
assign alert_if[12].alert_tx = `CHIP_HIER.u_otp_ctrl.alert_tx_o[0];
assign alert_if[13].alert_tx = `CHIP_HIER.u_otp_ctrl.alert_tx_o[1];
assign alert_if[14].alert_tx = `CHIP_HIER.u_lc_ctrl.alert_tx_o[0];
assign alert_if[15].alert_tx = `CHIP_HIER.u_lc_ctrl.alert_tx_o[1];
assign alert_if[16].alert_tx = `CHIP_HIER.u_lc_ctrl.alert_tx_o[2];
assign alert_if[17].alert_tx = `CHIP_HIER.u_pwrmgr_aon.alert_tx_o[0];
assign alert_if[18].alert_tx = `CHIP_HIER.u_rstmgr_aon.alert_tx_o[0];
assign alert_if[19].alert_tx = `CHIP_HIER.u_clkmgr_aon.alert_tx_o[0];
assign alert_if[20].alert_tx = `CHIP_HIER.u_sysrst_ctrl_aon.alert_tx_o[0];
assign alert_if[21].alert_tx = `CHIP_HIER.u_adc_ctrl_aon.alert_tx_o[0];
assign alert_if[22].alert_tx = `CHIP_HIER.u_pwm_aon.alert_tx_o[0];
assign alert_if[23].alert_tx = `CHIP_HIER.u_pinmux_aon.alert_tx_o[0];
assign alert_if[24].alert_tx = `CHIP_HIER.u_aon_timer_aon.alert_tx_o[0];
assign alert_if[25].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[0];
assign alert_if[26].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[1];
assign alert_if[27].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[2];
assign alert_if[28].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[3];
assign alert_if[29].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[4];
assign alert_if[30].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[5];
assign alert_if[31].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[6];
assign alert_if[32].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[7];
assign alert_if[33].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[8];
assign alert_if[34].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[9];
assign alert_if[35].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[10];
assign alert_if[36].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[11];
assign alert_if[37].alert_tx = `CHIP_HIER.u_sensor_ctrl_aon.alert_tx_o[12];
assign alert_if[38].alert_tx = `CHIP_HIER.u_sram_ctrl_ret_aon.alert_tx_o[0];
assign alert_if[39].alert_tx = `CHIP_HIER.u_sram_ctrl_ret_aon.alert_tx_o[1];
assign alert_if[40].alert_tx = `CHIP_HIER.u_flash_ctrl.alert_tx_o[0];
assign alert_if[41].alert_tx = `CHIP_HIER.u_flash_ctrl.alert_tx_o[1];
assign alert_if[42].alert_tx = `CHIP_HIER.u_flash_ctrl.alert_tx_o[2];
assign alert_if[43].alert_tx = `CHIP_HIER.u_flash_ctrl.alert_tx_o[3];
assign alert_if[44].alert_tx = `CHIP_HIER.u_rv_plic.alert_tx_o[0];
assign alert_if[45].alert_tx = `CHIP_HIER.u_aes.alert_tx_o[0];
assign alert_if[46].alert_tx = `CHIP_HIER.u_aes.alert_tx_o[1];
assign alert_if[47].alert_tx = `CHIP_HIER.u_hmac.alert_tx_o[0];
assign alert_if[48].alert_tx = `CHIP_HIER.u_kmac.alert_tx_o[0];
assign alert_if[49].alert_tx = `CHIP_HIER.u_keymgr.alert_tx_o[0];
assign alert_if[50].alert_tx = `CHIP_HIER.u_keymgr.alert_tx_o[1];
assign alert_if[51].alert_tx = `CHIP_HIER.u_csrng.alert_tx_o[0];
assign alert_if[52].alert_tx = `CHIP_HIER.u_entropy_src.alert_tx_o[0];
assign alert_if[53].alert_tx = `CHIP_HIER.u_entropy_src.alert_tx_o[1];
assign alert_if[54].alert_tx = `CHIP_HIER.u_edn0.alert_tx_o[0];
assign alert_if[55].alert_tx = `CHIP_HIER.u_edn1.alert_tx_o[0];
assign alert_if[56].alert_tx = `CHIP_HIER.u_sram_ctrl_main.alert_tx_o[0];
assign alert_if[57].alert_tx = `CHIP_HIER.u_sram_ctrl_main.alert_tx_o[1];
assign alert_if[58].alert_tx = `CHIP_HIER.u_otbn.alert_tx_o[0];
assign alert_if[59].alert_tx = `CHIP_HIER.u_otbn.alert_tx_o[1];
assign alert_if[60].alert_tx = `CHIP_HIER.u_rom_ctrl.alert_tx_o[0];
assign alert_if[61].alert_tx = `CHIP_HIER.u_rv_core_ibex_peri.alert_tx_o[0];
assign alert_if[62].alert_tx = `CHIP_HIER.u_rv_core_ibex_peri.alert_tx_o[1];
assign alert_if[63].alert_tx = `CHIP_HIER.u_rv_core_ibex_peri.alert_tx_o[2];
assign alert_if[64].alert_tx = `CHIP_HIER.u_rv_core_ibex_peri.alert_tx_o[3];
