// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef OPENTITAN_SW_DEVICE_LIB_OTBN_H_
#define OPENTITAN_SW_DEVICE_LIB_OTBN_H_

#include "sw/device/lib/dif/dif_otbn.h"

/**
 * @file
 * @brief OpenTitan Big Number Accelerator (OTBN) driver
 */

/**
 * Information about an embedded OTBN application image.
 *
 * All pointers reference data in the normal CPU address space.
 *
 * Use `OTBN_USE_APP()` together with `OTBN_APP_T_INIT()` to initialize this
 * structure.
 */
typedef struct otbn_app {
  /**
   * Start of OTBN instruction memory.
   */
  const char *imem_start;
  /**
   * End of OTBN instruction memory.
   */
  const char *imem_end;
  /**
   * Start of OTBN data memory.
   */
  const char *dmem_start;
  /**
   * End of OTBN data memory.
   */
  const char *dmem_end;
} otbn_app_t;

/**
 * A pointer to a symbol in OTBN's instruction or data memory.
 *
 * Use `OTBN_USE_PTR()` together with `OTBN_PTR_T_INIT()` to initialize this
 * type.
 *
 * The value of the pointer is an address in the normal CPU address space, and
 * must be first converted into OTBN address space before it can be used there.
 */
typedef char *otbn_ptr_t;

/**
 * The result of an OTBN operation.
 */
typedef enum otbn_result {
  /**
   * The operation succeeded.
   */
  kOtbnOk = 0,
  /**
   * An unspecified failure occurred.
   */
  kOtbnError = 1,
  /**
   * The precondition check for an argument passed into the function failed.
   */
  kOtbnBadArg = 2,
  /**
   * The chosen application is not part of the loaded application.
   */
  kOtbnFuncNotInApp = 3,
  /**
   * No application is loaded.
   */
  kOtbnAppNotLoaded = 4,
  /**
   * The execution of the application on OTBN failed.
   *
   * More specific error information can be obtained with
   * `dif_otbn_get_err_code()`.
   */
  kOtbnExecutionFailed = 5,
} otbn_result_t;

/**
 * OTBN context structure.
 *
 * Use `otbn_init()` to initialize.
 */
typedef struct otbn {
  /**
   * The OTBN DIF to access the hardware.
   */
  dif_otbn_t dif;

  /**
   * The application loaded or to be loaded into OTBN.
   */
  const otbn_app_t *app;

  /**
   * Is the application loaded into OTBN?
   */
  bool app_is_loaded;
} otbn_t;

/**
 * Makes an embedded OTBN application image available for use.
 *
 * Make symbols available that indicate the start and the end of instruction
 * and data memory regions, as they are stored in the device memory.
 *
 * @param app_name Name of the application to load, which is typically the
 *                 name of the main (assembly) source file.
 */
#define OTBN_USE_APP(app_name)                            \
  extern const char _otbn_app_##app_name##__imem_start[]; \
  extern const char _otbn_app_##app_name##__imem_end[];   \
  extern const char _otbn_app_##app_name##__dmem_start[]; \
  extern const char _otbn_app_##app_name##__dmem_end[]

/**
 * Initializes the OTBN application information structure
 *
 * After making all required symbols from the application image available
 * through `OTBN_USE_APP()`, use this macro to initialize an `otbn_app_t`
 * struct with those symbols.
 *
 * @param app_name Name of the application to load.
 * @see OTBN_USE_APP()
 */
#define OTBN_APP_T_INIT(app_name)                     \
  (otbn_app_t) {                                      \
    .imem_start = _otbn_app_##app_name##__imem_start, \
    .imem_end = _otbn_app_##app_name##__imem_end,     \
    .dmem_start = _otbn_app_##app_name##__dmem_start, \
    .dmem_end = _otbn_app_##app_name##__dmem_end,     \
  }

/**
 * Makes a symbol in the OTBN application image available.
 *
 * Symbols are typically function or data pointers, i.e. labels in assembly
 * code.
 *
 * @param app_name    Name of the application the function is contained in.
 * @param symbol_name Name of the symbol (function, label).
 */
#define OTBN_USE_PTR(app_name, symbol_name) \
  extern const char _otbn_app_##app_name##_##symbol_name[]

/**
 * Initializes an `otbn_ptr_t` structure.
 */
#define OTBN_PTR_T_INIT(app_name, symbol_name) \
  (otbn_ptr_t) _otbn_app_##app_name##_##symbol_name

/**
 * Initializes the OTBN context structure.
 *
 * @param ctx The context object
 * @param dif_config The OTBN DIF configuration (passed on to the DIF).
 * @return The result of the operation.
 */
otbn_result_t otbn_init(otbn_t *ctx, const dif_otbn_config_t *dif_config);

/**
 * (Re-)loads the RSA application into OTBN.
 *
 * Load the application image with both instruction and data segments into OTBN.
 *
 * @param ctx The context object.
 * @param app The application to load into OTBN.
 * @return The result of the operation.
 */
otbn_result_t otbn_load_app(otbn_t *ctx, const otbn_app_t *app);

/**
 * Calls a function on OTBN.
 *
 * Set the entry point (start address) of OTBN to the desired function, and
 * starts the OTBN operation.
 *
 * Use `otbn_busy_wait_for_done()` to wait for the function call to complete.
 *
 * @param ctx The context object.
 * @param func The function to be called.
 * @return The result of the operation.
 */
otbn_result_t otbn_call_function(otbn_t *ctx, const otbn_ptr_t func);

/**
 * Busy waits for OTBN to be done with its operation.
 *
 * @param ctx The context object.
 * @return The result of the operation.
 */
otbn_result_t otbn_busy_wait_for_done(otbn_t *ctx);

/**
 * Copies data from the CPU memory to OTBN data memory.
 *
 * @param ctx The context object.
 * @param dest Pointer to the destination in OTBN's data memory.
 * @param src Source of the data to copy.
 * @param len_bytes Number of bytes to copy.
 * @return The result of the operation.
 */
otbn_result_t otbn_memcpy_data_to_otbn(otbn_t *ctx, const otbn_ptr_t dest,
                                       const void *src, size_t len_bytes);

/**
 * Copies data from OTBN's data memory to CPU memory.
 *
 * @param ctx the context object
 * @param[out] dest destination of the copied data in main memory (preallocated)
 * @param src pointer in OTBN data memory to copy from
 * @param len_bytes number of bytes to copy
 * @return The result of the operation.
 */
otbn_result_t otbn_memcpy_data_from_otbn(otbn_t *ctx, void *dest,
                                         const otbn_ptr_t src,
                                         size_t len_bytes);

/**
 * Overwrites all of OTBN's data memory with zeros.
 *
 * This function tries to perform the operation for all data words, even if
 * a single write fails.
 *
 * @param ctx the context object
 * @return The result of the operation.
 */
otbn_result_t otbn_zero_data_memory(otbn_t *ctx);

#endif  // OPENTITAN_SW_DEVICE_LIB_OTBN_H_
