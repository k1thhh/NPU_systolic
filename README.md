````markdown
# 🧠 Edge-AI NPU Core: 8×8 INT4 Systolic Array

A small, tapeout-ready hardware AI accelerator implementing an **8×8 weight-stationary systolic array** for INT4 matrix multiplication, written in **SystemVerilog** and hardened to **GDSII on the SkyWater 130nm PDK** as a Tiny Tapeout project.

The accelerator uses **64 custom Processing Elements (PEs)** arranged in an 8×8 grid, with INT4 weights and activations and INT16 accumulators. Data is streamed through the systolic array to perform matrix multiplication efficiently while minimizing repeated memory access. :contentReference[oaicite:1]{index=1}

<p align="center">

<img src="https://img.shields.io/badge/Domain-Edge%20AI-blue" alt="Edge AI">
<img src="https://img.shields.io/badge/Architecture-NPU-orange" alt="NPU">
<img src="https://img.shields.io/badge/Precision-INT4-green" alt="INT4">
<img src="https://img.shields.io/badge/Array-8×8-purple" alt="8x8 Systolic Array">
<img src="https://img.shields.io/badge/Process-SkyWater%20130nm-red" alt="SkyWater 130nm">
<img src="https://img.shields.io/badge/Status-Tapeout%20Ready-success" alt="Tapeout Ready">

</p>

> 🚀 **Tapeout Status:** SUCCESS — GDSII generated

---

## Why

AI workloads rely heavily on matrix multiplication, but repeatedly moving data between computation units and memory can consume significant **power, bandwidth, and time**.

A systolic array addresses this by keeping computation distributed across a grid of Processing Elements and continuously streaming data through the array.

This project implements a compact **8×8 NPU accelerator** designed specifically around INT4 arithmetic, allowing the architecture to fit within the physical area constraints of the target SkyWater 130nm Tiny Tapeout implementation.

The design focuses on:

- **Efficient matrix multiplication**
- Reduced data movement
- Weight-stationary computation
- Low-bit-width INT4 arithmetic
- Compact hardware implementation
- RTL-to-GDSII physical design
- Gate-level verification of the hardened design

## Features

- 🧠 **8×8 systolic-array NPU architecture**
- 🔢 **64 custom Processing Elements**
- ⚡ INT4 weights and activations
- ➕ INT16 accumulators
- 🔄 Weight-stationary dataflow
- ➡️ Activations flow left-to-right
- ⬇️ Partial sums flow top-to-bottom
- 📦 8-bit to 32-bit input staging buffer
- 🔌 Tiny Tapeout-compatible top-level wrapper
- 🏭 SkyWater 130nm physical implementation
- 🗺️ OpenLane-based hardening
- 💾 GDSII generation
- 🧪 cocotb RTL verification
- 🔬 Gate-level simulation
- 📈 Cycle-accurate wavefront verification
- ⏱️ 50 MHz target clock
- 📐 8×2 Tiny Tapeout tile footprint

## System Architecture

```text
                    Input Activations
                           │
                           ▼
                  ┌─────────────────┐
                  │  Input Buffer   │
                  │   8 → 32 bit    │
                  └────────┬────────┘
                           │
                           ▼
             ┌───────────────────────────┐
             │       8 × 8 Systolic      │
             │           Array           │
             │                           │
             │  PE → PE → PE → ... → PE │
             │  ↓    ↓    ↓          ↓   │
             │  PE → PE → PE → ... → PE │
             │  ↓    ↓    ↓          ↓   │
             │  ⋮    ⋮    ⋮          ⋮   │
             │  PE → PE → PE → ... → PE │
             └────────────┬──────────────┘
                          │
                          ▼
                  128-bit Result Bus
                          │
                          ▼
                    Output Mux
                          │
                          ▼
                       uo_out
````

**Flow:** input bytes → input staging buffer → INT4 activation stream → 8×8 Processing Element array → accumulated partial sums → output multiplexer → Tiny Tapeout output pins.

The array contains **64 Processing Elements**, with activations moving horizontally and partial sums propagating vertically through the grid. 

## Processing Elements

Each Processing Element acts as an individual **INT4 multiply-accumulate (MAC) unit**.

```text
          INT4 Weight
               │
               ▼
        ┌──────────────┐
INT4 ──►│   INT4 MAC   │
Activation│     PE      │
        └──────┬───────┘
               │
               ▼
        INT16 Partial Sum
```

Each PE:

* Latches an INT4 weight
* Receives INT4 activations
* Performs multiplication
* Accumulates into an INT16 partial sum
* Passes the resulting partial sum to the next PE in the column

The 64 PEs are implemented in `src/processing_element.sv` and connected through `src/systolic_array_8x8.sv`. 

## Systolic Array

The accelerator uses a **weight-stationary dataflow**.

```text
             Activations →
       ┌────┬────┬────┬────┐
       │ PE │ PE │ PE │ PE │
       ├────┼────┼────┼────┤
       │ PE │ PE │ PE │ PE │
       ├────┼────┼────┼────┤
       │ PE │ PE │ PE │ PE │
       ├────┼────┼────┼────┤
       │ PE │ PE │ PE │ PE │
       └────┴────┴────┴────┘
          ↓    ↓    ↓    ↓
       Partial Sums
```

Weights remain stationary inside the Processing Elements while activations continuously stream through the array.

This minimizes unnecessary memory accesses and allows the same weight to participate in multiple multiply-accumulate operations.

## Dataflow

The accelerator follows a **weight-stationary systolic dataflow**:

```text
Weights
  │
  ▼
Loaded into PEs
  │
  ▼
Remain Stationary
  │
  │
Activations ──────────────►
  │
  ▼
Multiply with Stored Weight
  │
  ▼
Accumulate
  │
  ▼
Partial Sum ──────────────►
          Down the Column
```

Activations propagate from **left to right**, while accumulated partial sums move **from top to bottom** through the array. 

## Input Staging Buffer

The Tiny Tapeout interface provides a relatively narrow input interface, while the internal systolic array requires wider activation words.

The `input_buffer.sv` module bridges this difference.

```text
8-bit Input
    │
    ▼
┌───────────────┐
│ Input Buffer  │
│ 8 → 32 bits   │
└───────┬───────┘
        │
        ▼
32-bit Activation Word
        │
        ▼
8×8 Systolic Array
```

The input buffer is implemented as an **8-to-32-bit shift register**, assembling four 8-bit input bytes into one 32-bit activation word before passing it to the array. 

## Output Architecture

The internal result consists of **eight 16-bit accumulators**, producing a total 128-bit result bus.

Because the Tiny Tapeout interface provides an 8-bit output path, the top-level wrapper multiplexes the internal results onto the output pins.

```text
        8 × 16-bit Accumulators
                 │
                 ▼
           128-bit Bus
                 │
                 ▼
            Output Mux
          ┌──────┴──────┐
          │             │
       col_sel       byte_sel
          │             │
          └──────┬──────┘
                 ▼
               uo_out
               8 bits
```

The top-level wrapper is implemented in `src/tt_um_npu_core.sv`. 

## Technologies Used

* **SystemVerilog** — RTL implementation
* **SkyWater 130nm PDK** — target semiconductor process
* **OpenLane** — physical synthesis and hardening
* **Icarus Verilog** — RTL and gate-level simulation
* **cocotb** — Python-based verification
* **GDSII** — final physical layout
* **Tiny Tapeout** — tapeout platform

## Hardware Specifications

| Parameter             | Specification                        |
| --------------------- | ------------------------------------ |
| Architecture          | 8×8 Weight-Stationary Systolic Array |
| Processing Elements   | 64                                   |
| Weight Precision      | INT4                                 |
| Activation Precision  | INT4                                 |
| Accumulator Precision | INT16                                |
| Process Node          | SkyWater 130nm                       |
| Standard Cell Library | `sky130_fd_sc_hd`                    |
| Clock                 | 50 MHz                               |
| Tiny Tapeout Area     | 8×2 tiles                            |
| Tapeout Status        | GDSII generated                      |
| Verification          | cocotb RTL + gate-level              |



## Repository Structure

```text
.
├── src/
│   ├── tt_um_npu_core.sv
│   ├── systolic_array_8x8.sv
│   ├── processing_element.sv
│   ├── input_buffer.sv
│   └── config.json
│
├── test/
│   ├── test.py
│   ├── tb.v
│   └── Makefile
│
├── docs/
│   ├── info.md
│   └── images/
│       └── gds_render.png
│
└── info.yaml
```

The RTL, testbench, documentation, physical-design configuration, and Tiny Tapeout metadata are organized separately within the repository. 

## Getting Started

### Requirements

* Icarus Verilog
* Python 3
* cocotb
* Make
* OpenLane / SkyWater 130nm PDK for physical hardening
* GTKWave for optional waveform inspection

### 1. Install Dependencies

Navigate to the test directory:

```bash
cd test
pip install -r requirements.txt
```

### 2. Run RTL Simulation

Build and execute the cocotb RTL testbench:

```bash
make -B
```

This runs the testbench against the SystemVerilog RTL sources in `src/`. 

### 3. Run Gate-Level Simulation

After hardening the design with OpenLane, copy the generated gate-level netlist to:

```text
test/gate_level_netlist.v
```

Then run:

```bash
make -B GATES=yes
```

This verifies the hardened gate-level implementation rather than only the RTL. 

## Verification

The project uses a **cycle-accurate cocotb testbench** to verify both the RTL and routed SkyWater 130nm gate-level netlist.

The verification process:

```text
Testbench
    │
    ▼
Load Weights
    │
    ▼
Stream Activations
    │
    ▼
8×8 Systolic Array
    │
    ▼
Partial Sum Wavefront
    │
    ▼
Read Results
    │
    ▼
Compare Expected Output
```

The test loads a uniform matrix of weights, streams activations through the array, and checks that the accumulated partial sums propagate through the systolic columns as expected. 

## Tapeout Journey

The project went beyond RTL simulation and encountered several practical physical-design and gate-level verification issues during the RTL-to-GDSII flow.

### 1. Single-Trigger Logic Issue

Control paths were restructured around continuous `assign` wiring to maintain live connections between external pads and internal logic.

### 2. Area Constraint

The initial implementation used **INT8 multipliers and INT32 accumulators**, which exceeded the physical area budget.

The design was optimized to:

```text
INT8 → INT4
INT32 → INT16
```

This significantly reduced the logic footprint and allowed the complete 64-PE array to fit within the available tile budget. 

### 3. Gate-Level Setup/Hold Violations

Gate-level simulation initially produced metastable `X` states because testbench inputs were driven too close to the active clock edge.

The testbench was modified to drive inputs on the **falling edge of the clock**, providing a full half-cycle for signals to propagate before the capturing edge. 

### 4. X-Poisoning at Time Zero

Unknown values at simulation startup could propagate through the entire systolic array.

A short startup delay was introduced to ensure all input signals were initialized before the clock began. 

### 5. Power Tie-Off

Gate-level elaboration exposed floating `VPWR` and `VGND` standard-cell power nets.

A simulation-only `$deposit` mechanism was used under the `GL_TEST` macro to provide valid power levels without modifying the physical layout. 

## Results

The project successfully achieved:

* ✅ **GDSII generation**
* ✅ 8×8 systolic array implementation
* ✅ 64 custom Processing Elements
* ✅ INT4 weight and activation datapath
* ✅ INT16 accumulation
* ✅ Weight-stationary dataflow
* ✅ SkyWater 130nm physical implementation
* ✅ 8×2 Tiny Tapeout tile footprint
* ✅ RTL verification
* ✅ Gate-level verification
* ✅ Cycle-accurate systolic wavefront verification
* ✅ 50 MHz clock target

## Impact & Results

The project demonstrates a complete **RTL-to-GDSII hardware AI accelerator flow**, rather than stopping at functional RTL simulation.

The final implementation successfully integrates:

**AI computation → RTL design → verification → synthesis → physical design → GDSII**

The move from INT8/INT32 arithmetic to **INT4/INT16 arithmetic** was particularly important for satisfying the physical area constraint while preserving the full 64-PE systolic architecture. 

## Limitations

* The accelerator is specialized for low-precision INT4 matrix multiplication.
* The design does not implement higher-precision INT8/INT16 arithmetic in the final physical implementation.
* The output interface exposes the internal result bus through an 8-bit multiplexed interface.
* The architecture is fixed at an 8×8 systolic array.
* The current verification focuses on the implemented systolic matrix-multiplication datapath.
* Tiny Tapeout tile-area constraints influenced the final arithmetic precision and architecture.

## Future Scope

* Support for INT8 and mixed-precision inference
* Larger systolic arrays such as 16×16 or 32×32
* Sparse matrix acceleration
* Activation-function hardware
* On-chip memory and buffering
* Quantized neural-network inference
* CNN and transformer-specific datapaths
* Improved output bandwidth
* DMA-based data movement
* Power and clock gating
* FPGA prototyping
* Silicon bring-up and post-tapeout characterization
* Performance-per-watt optimization

## Project Highlights

* 🔹 **8×8 weight-stationary systolic array**
* 🔹 **64 custom Processing Elements**
* 🔹 INT4 weights and activations
* 🔹 INT16 accumulators
* 🔹 8-bit → 32-bit input staging
* 🔹 128-bit internal result bus
* 🔹 Tiny Tapeout-compatible wrapper
* 🔹 **SkyWater 130nm implementation**
* 🔹 **GDSII successfully generated**
* 🔹 **8×2 Tiny Tapeout tile footprint**
* 🔹 50 MHz clock
* 🔹 cocotb RTL verification
* 🔹 Gate-level simulation
* 🔹 OpenLane physical hardening
* 🔹 Real RTL-to-GDSII debugging experience
* 🔹 Area-driven INT4 quantization
* 🔹 Cycle-accurate wavefront verification

## Documentation

* [`docs/info.md`](docs/info.md) — Tiny Tapeout project datasheet, pin-level protocol, and testing procedure
* [`test/README.md`](test/README.md) — verification and simulation details
* [`info.yaml`](info.yaml) — Tiny Tapeout project configuration and pinout

## Key Concepts Demonstrated

* Edge AI Hardware
* Neural Processing Units
* Systolic Arrays
* Matrix Multiplication
* Weight-Stationary Dataflow
* Processing Elements
* Multiply-Accumulate Units
* INT4 Quantization
* Hardware Accelerators
* SystemVerilog RTL
* RTL Verification
* cocotb
* Gate-Level Simulation
* OpenLane
* Physical Design
* SkyWater 130nm
* GDSII Generation
* Tiny Tapeout
* RTL-to-GDSII Flow

## Acknowledgements

* **Tiny Tapeout** — open-source ASIC/tapeout platform
* **SkyWater** — 130nm open-source PDK
* **OpenLane** — RTL-to-GDSII physical-design flow
* **cocotb** — Python-based hardware verification framework

```
```
