### Hippo UART

Break out of the exceedingly simple Hippomenes UART HDL implementation.
Intended as a simple interface to the host when testing new component implementations on HW.

## Usage

Run

```vivado --mode tcl source hippo_uart.tcl```

in `./fpga/` to generate the `hippo_uart.xpr` Vivado project file. The project, and included constraints assume an Arty A35T board.

An example of pushing an ASCII B over the UART at some period is available in the fpga_uart module (`./hdl/src/fpga_uart.sv`). This example should be point-and-click synthesizeable and programmable using Vivado, and should be enough to get you started with pushing arbitrary data over the link.
