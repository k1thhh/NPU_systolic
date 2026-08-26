# Testbench

This is the [cocotb](https://docs.cocotb.org/en/stable/) testbench for the Edge-AI NPU Core. It drives the
`tt_um_npu_core` DUT (via [`tb.v`](tb.v)) through a weight-load phase and an activation-flood phase, then
checks the systolic wavefront output on `uo_out`. See [`../docs/info.md`](../docs/info.md) for the pin-level
protocol and the top-level [README](../README.md) for the project overview.

## Setup

```sh
pip install -r requirements.txt
```

Requires [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`) on your `PATH`.

## Running the tests

RTL simulation:

```sh
make -B
```

Gate-level simulation, once you have hardened the design and produced a gate-level netlist (see the `gds`
GitHub Actions workflow, or run OpenLane locally): copy the resulting netlist to `test/gate_level_netlist.v`,
then run:

```sh
make -B GATES=yes
```

## Viewing waveforms

```sh
gtkwave tb.vcd tb.gtkw
```
