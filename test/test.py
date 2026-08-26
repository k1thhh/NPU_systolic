import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, Timer

@cocotb.test()
async def flood_test(dut):
    """THE WAVEFRONT TEST: Hardened against Gate-Level X-Poisoning."""
    
    dut.ena.value = 1
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.clk.value = 0
    
    await Timer(1, units="ns")
    
    cocotb.start_soon(Clock(dut.clk, 20, units="ns").start())

    for _ in range(10): 
        await FallingEdge(dut.clk)
        
    dut.rst_n.value = 1
    await FallingEdge(dut.clk)

    dut._log.info("--- PHASE 1: FLOODING THE GRID WITH WEIGHTS ---")
    dut.uio_in.value = 0b00000011 # CS=1, WE=1
    
    for _ in range(64):
        dut.ui_in.value = 1
        await FallingEdge(dut.clk)

    dut._log.info("--- PHASE 2: FLOODING ACTIVATIONS & WATCHING PINS ---")
    dut.uio_in.value = 0b00000010 # CS=1, WE=0
    
    success = False
    
    for cycle in range(50):
        dut.ui_in.value = 1
        await FallingEdge(dut.clk)
        raw_out = str(dut.uo_out.value)
        
        if "x" in raw_out.lower() or "z" in raw_out.lower():
            dut._log.info(f"Cycle {cycle}: Pins physically transitioning ({raw_out})...")
            continue
            
        output_val = int(dut.uo_out.value)
        dut._log.info(f"Cycle {cycle}: Output Pin = {output_val}")
       
        if output_val == 8:
            success = True
            dut._log.info(" SUCCESS! Caught the wave in the physical Gate-Level Netlist!")
            break
            
    assert success, "The physical silicon failed to compute the correct math!"
