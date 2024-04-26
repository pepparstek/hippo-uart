// fpga_uart
// example of how the UART can be used to push data over the wire.
`timescale 1ns / 1ps


module fifo_spram_top
  import decoder_pkg::*;
(
    input sysclk,
    input logic [1:0] sw,
    output logic rx  // host
);

  logic clk;
  logic tmp_sw1;
  logic locked;
  assign tmp_sw1 = sw[1];
  clk_wiz_0 clk_gen (
      // Clock in ports
      .clk_in1(sysclk),
      // Clock out ports
      .clk_out1(clk),
      // Status and control signals
      .reset(tmp_sw1),
      .locked
  );

  logic [7:0] fifo_data;
  logic uart_next;
  logic fifo_have_next;
  logic fifo_write_enable_in;
  word prescaler;
  word r_count;
  word fifo_data_in;
  r rs1_zimm;
  CsrAddrT csr_addr;
  logic csr_enable;
  csr_op_t csr_op;
  assign prescaler = 0;
  fifo_spram fifo (
      .clk_i(clk),
      .reset_i(tmp_sw1),
      .next(uart_next),
      .csr_enable(csr_enable),
      .csr_addr(csr_addr),
      .rs1_zimm(rs1_zimm),
      .rs1_data(fifo_data_in),
      .csr_op(csr_op),
      .data(data),
      .csr_data_out(csr_data_out),
      .have_next(have_next)
  );
  always_ff @(posedge clk) begin
    if (r_count[22] == 1) begin
      fifo_data_in <= 'h42;
      fifo_write_enable_in <= 1;
      r_count <= 0;
    end else begin
      fifo_write_enable_in <= 0;
      r_count <= r_count + 1;
    end
  end
endmodule
