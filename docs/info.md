## How it works

This project is an 8x8 **weight-stationary systolic array** for INT4 matrix multiplication, built as a Tiny Tapeout ASIC.

- 64 `processing_element` cores (Micro-MACs) arranged in an 8x8 grid, each holding one INT4 weight and accumulating a signed INT16 partial sum.
- An `input_buffer` shift-register stages four 8-bit input bytes into a 32-bit activation word before it is fed into the array.
- Weights and activations enter through the 8-bit `ui_in` bus; the row of partial sums exits the bottom of the grid as a 128-bit bus (8 columns x 16-bit accumulators) and is multiplexed down to the 8-bit `uo_out` bus.

## How to test

1. Hold `weight_load_en` (`uio_in[0]`) high and `buffer_cs` (`uio_in[1]`) high while streaming 8-bit weight values into `ui_in`. Each weight is latched into its processing element on `weight_load_en`.
2. Drop `weight_load_en` low and keep `buffer_cs` high to stream activation bytes into `ui_in`. Values ripple through the grid one cycle per row/column (the systolic wavefront).
3. Select which of the 8 accumulator columns to read using `col_sel` (`uio_in[4:2]`), and which byte of the 16-bit result using `byte_sel` (`uio_in[5]`). Read the selected byte from `uo_out`.
4. Repeat with `byte_sel` toggled to read the other half of the 16-bit accumulated result.

See [`test/test.py`](../test/test.py) for a cocotb testbench that drives this sequence and verifies the systolic wavefront against both the RTL and the gate-level netlist.

## External hardware

None. All inputs/outputs are exercised over the standard Tiny Tapeout `ui_in` / `uo_out` / `uio` pins.
