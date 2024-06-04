// fpga_uart
// example of how the UART can be used to push data over the wire.
`timescale 1ns / 1ps


module fpga_uart
  import decoder_pkg::*;
  import arty_pkg::*;
  import debug_pkg::*;
(
    input sysclk,
    input logic [1:0] sw,
    output LedT led_r,
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
  logic [7:0] fifo_data_in;
  assign prescaler = 0;
  uart uart_i (
      .clk_i    (clk),
      .reset_i  (tmp_sw1),
      .prescaler(prescaler),       // this can be a config register, for now just wire it to a 0
      .d_in     (fifo_data),       // data in from fifo
      .rts      (fifo_have_next),  // queue ready signal
      //input logic cmp,
      .tx       (rx),              // the tx pin of the UART
      .next     (uart_next)        // next word request to the fifo
  );

  fifo fifo_i (
      .clk_i(clk),
      .reset_i(tmp_sw1),
      .next(uart_next),
      .data_i(fifo_data_in),
      .write_enable(fifo_write_enable_in),
      //input logic cmp,
      .data(fifo_data),
      .have_next(fifo_have_next)
  );

  always_ff @(posedge clk) begin
    if (sw[1]) begin
      for (integer k = 0; k < LedWidth; k++) begin
        led_r[k] <= 0;
      end
    end else begin
      led_r[0] <= r_count[23];
    end
  end


  reg [7:0] chunks[5];


  assign chunks[0] = dmi_data[39:32];
  assign chunks[1] = dmi_data[31:24];
  assign chunks[2] = dmi_data[23:16];
  assign chunks[3] = dmi_data[15:8];
  assign chunks[4] = dmi_data[7:0];



  logic [2:0] cnt;  // Wrapped around and wrote on extra byte when 2:0
  logic written_in, written_out;
  logic snapshot;
  always_ff @(posedge clk) begin
    if (DMI_CAPTURE && DMI_SEL && (dmi_req.op == DMINop)) begin
      cnt <= 0;
      snapshot <= 1;
    end

    fifo_write_enable_in <= 0;
    //r_count <= r_count + 1;
    // chunks[0] <= dmi_data[39:32];
    // chunks[1] <= dmi_data[31:24];
    // chunks[2] <= dmi_data[23:16];
    // chunks[3] <= dmi_data[15:8];
    // chunks[4] <= dmi_data[7:0];

    //    chunks[0] <= 'h41;
    //    chunks[1] <= 'h42;
    //    chunks[2] <= 'h43;
    //    chunks[3] <= 'h44;
    //    chunks[4] <= 'h45;
    if (DMI_UPDATE && DMI_SEL && (dmi_req.op != DMINop)) begin
      // if (snapshot) begin
      //   snapshot <= 0;
      // end

      if (cnt < 5) begin
        fifo_data_in <= chunks[cnt];
        fifo_write_enable_in <= 1;
        cnt <= cnt + 1;
      end else begin
        fifo_write_enable_in <= 0;
      end

    end

  end













  // DTMCS and DMI datastreams
  localparam DTMCS_DATAWIDTH = 32;
  localparam DMI_DATAWIDTH = 40;
  localparam DM_REGISTER_SIZE = 6;


  (* KEEP = "TRUE" *) reg [DTMCS_DATAWIDTH-1:0] dtmcs_data;
  (* KEEP = "TRUE" *) reg [DMI_DATAWIDTH-1:0] dmi_data;
  (* KEEP = "TRUE" *) reg [31:0] dm_register[130];

  // Debug signals
  // (* KEEP = "TRUE" *) logic [31:0] dm_reg0;
  // (* KEEP = "TRUE" *) logic [31:0] dm_reg1;
  // (* KEEP = "TRUE" *) logic [31:0] dm_reg2;
  // (* KEEP = "TRUE" *) logic [31:0] dm_reg3;
  // (* KEEP = "TRUE" *) logic [31:0] dm_reg4;
  // (* KEEP = "TRUE" *) logic [31:0] dm_reg5;
  // (* KEEP = "TRUE" *) logic [31:0] dm_reg15;
  // (* KEEP = "TRUE" *) logic [31:0] dm_reg16;
  // (* KEEP = "TRUE" *) logic [31:0] dm_reg17;
  // (* KEEP = "TRUE" *) logic [31:0] dm_reg18;
  // (* KEEP = "TRUE" *) logic [31:0] dm_reg19;
  // (* KEEP = "TRUE" *) logic [31:0] dm_reg20;

  // (* KEEP = "TRUE" *)assign dm_reg0 = dm_register[0];
  // (* KEEP = "TRUE" *)assign dm_reg1 = dm_register[1];
  // (* KEEP = "TRUE" *)assign dm_reg2 = dm_register[2];
  // (* KEEP = "TRUE" *)assign dm_reg3 = dm_register[3];
  // (* KEEP = "TRUE" *)assign dm_reg4 = dm_register[4];
  // (* KEEP = "TRUE" *)assign dm_reg5 = dm_register[5];
  // (* KEEP = "TRUE" *)assign dm_reg15 = dm_register[15];
  // (* KEEP = "TRUE" *)assign dm_reg16 = dm_register[16];
  // (* KEEP = "TRUE" *)assign dm_reg17 = dm_register[17];
  // (* KEEP = "TRUE" *)assign dm_reg18 = dm_register[18];
  // (* KEEP = "TRUE" *)assign dm_reg19 = dm_register[19];
  // (* KEEP = "TRUE" *)assign dm_reg20 = dm_register[20];






  // ################ DTM/DM communication ################
  // Explanation:
  // Used for telling the state machine when it can process a request/response
  dmi_interface_signals_t dmi_interface_signals;  // NOT IMPLEMENTED YET




  // ################ DTMCS Specifics ################

  // Initializing DTMCS structs
  dtmcs_t dtmcs;
  dtmcs_errinfo_e dtmcs_errinfo;

  assign DTMCS_TDO   = dtmcs_data[0];
  assign dtmcs_clear = dtmcs.dtmhardreset;

  // DEBUG SIGNALS
  //  (* KEEP = "TRUE" *) logic [31:21] dtmcs_zero;
  //  (* KEEP = "TRUE" *) logic [20:18] dtmcs_zero;
  //  (* KEEP = "TRUE" *) logic dtmcs_errorinfo;
  //  (* KEEP = "TRUE" *) logic dtmcs_dtmhardreset;
  //  (* KEEP = "TRUE" *) logic dtmcs_dmireset;
  //  (* KEEP = "TRUE" *) logic dtmcs_zero_;
  //  (* KEEP = "TRUE" *) logic [14:12] dtmcs_idle;
  //  (* KEEP = "TRUE" *) logic [11:10] dtmcs_dmistat;
  //  (* KEEP = "TRUE" *) logic [9:4] dtmcs_abits;
  //  (* KEEP = "TRUE" *) logic [3:0] dtmcs_version;
  //  assign dtmcs_zero         = dtmcs.zero;
  //  assign dtmcs_errorinfo    = dtmcs.errinfo;
  //  assign dtmcs_dtmhardreset = dtmcs.dtmhardreset;
  //  assign dtmcs_dmireset     = dtmcs.dmireset;
  //  assign dtmcs_zero_        = dtmcs.zero_;
  //  assign dtmcs_idle         = dtmcs.idle;
  //  assign dtmcs_dmistat      = dtmcs.dmistat;
  //  assign dtmcs_abits        = dtmcs.abits;
  //  assign dtmcs_version      = dtmcs.version;





  // ################ DMI Specifics ################

  // Initializing DMI structs
  dmi_t dmi_resp, dmi_req;
  dmi_state_e dmi_state;
  dmi_op_e dmi_ops;

  (* KEEP = "TRUE" *) logic dmi_clear;
  assign DMI_TDO   = dmi_data[0];
  // Had to remove DMI_RESET from dmi_clear. For some reason it forces a reset
  // after DMI_UPDATE which overwrites the dmi_req and dmi_resp registers and
  // no data can be handled. DMI_RESET seems to run every so often.
  assign dmi_clear = DMI_RESET || (DMI_UPDATE && DMI_SEL && dtmcs.dmireset) || sw[1];
  (* KEEP = "TRUE" *)logic running;  // Not really used.
  (* KEEP = "TRUE" *)logic write_enabled;  // Enabled by default. If op == read, then don't write
  logic [1:0] error_in, error_out;  // Handles errors during runs

  // Debug signals
  // (* KEEP = "TRUE" *) logic [DM_REGISTER_SIZE - 1:0] dmi_req_addr;
  // (* KEEP = "TRUE" *) logic [31:0] dmi_req_data;
  // (* KEEP = "TRUE" *) logic [1:0] dmi_req_op;
  // assign dmi_req_addr = dmi_req.address;
  // assign dmi_req_data = dmi_req.data;
  // assign dmi_req_op   = dmi_req.op;

  // (* KEEP = "TRUE" *) logic [DM_REGISTER_SIZE - 1:0] dmi_resp_addr;
  // (* KEEP = "TRUE" *) logic [31:0] dmi_resp_data;
  // (* KEEP = "TRUE" *) logic [1:0] dmi_resp_op;
  // assign dmi_resp_addr = dmi_resp.address;
  // assign dmi_resp_data = dmi_resp.data;
  // assign dmi_resp_op   = dmi_resp.op;










  // ################ DM Specifics ################
  dmstatus_t dm_status;



  // Setting up scanchain for DTMCS
  (* KEEP = "TRUE" *) logic DTMCS_CAPTURE;
  (* KEEP = "TRUE" *) logic DTMCS_DRCK;
  (* KEEP = "TRUE" *) logic DTMCS_RESET;
  (* KEEP = "TRUE" *) logic DTMCS_RUNTEST;
  (* KEEP = "TRUE" *) logic DTMCS_SEL;
  (* KEEP = "TRUE" *) logic DTMCS_SHIFT;
  (* KEEP = "TRUE" *) logic DTMCS_TCK;
  (* KEEP = "TRUE" *) logic DTMCS_TDI;
  (* KEEP = "TRUE" *) logic DTMCS_TMS;
  (* KEEP = "TRUE" *) logic DTMCS_UPDATE;
  (* KEEP = "TRUE" *) logic DTMCS_TDO;

  BSCANE2 #(
      .JTAG_CHAIN(3)  // Value for USER command. USER3 0x22   
  ) bse2_dtmcs_inst (
      // Outputs
      .CAPTURE(DTMCS_CAPTURE),  // 1-bit output: CAPTURE output from TAP controller.
      .DRCK(DTMCS_DRCK),         // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
      // SHIFT are asserted.
      .RESET(DTMCS_RESET),  // 1-bit output: Reset output for TAP controller.
      .RUNTEST(DTMCS_RUNTEST),   // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(DTMCS_SEL),  // 1-bit output: USER instruction active output.
      .SHIFT(DTMCS_SHIFT),  // 1-bit output: SHIFT output from TAP controller.
      .TCK(DTMCS_TCK),  // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(DTMCS_TDI),  // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(DTMCS_TMS),  // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(DTMCS_UPDATE),  // 1-bit output: UPDATE output from TAP controller

      // Inputs
      .TDO(DTMCS_TDO)  // 1-bit input: Test Data Output (TDO) input for USER function.
  );






  // Setting up scanchain for DMI
  (* KEEP = "TRUE" *)logic DMI_CAPTURE;
  (* KEEP = "TRUE" *)logic DMI_DRCK;
  (* KEEP = "TRUE" *)logic DMI_RESET;
  (* KEEP = "TRUE" *)logic DMI_RUNTEST;
  (* KEEP = "TRUE" *)logic DMI_SEL;
  (* KEEP = "TRUE" *)logic DMI_SHIFT;
  (* KEEP = "TRUE" *)logic DMI_TCK;
  (* KEEP = "TRUE" *)logic DMI_TDI;
  (* KEEP = "TRUE" *)logic DMI_TMS;
  (* KEEP = "TRUE" *)logic DMI_UPDATE;
  (* KEEP = "TRUE" *)logic DMI_TDO;

  // DMI
  BSCANE2 #(
      .JTAG_CHAIN(4)  // Value for USER command. USER4 0x23
  ) bse2_dmi_inst (
      // Outputs
      .CAPTURE(DMI_CAPTURE),  // 1-bit output: CAPTURE output from TAP controller.
      .DRCK(DMI_DRCK),         // 1-bit output: Gated TCK output. When SEL is asserted, DRCK toggles when CAPTURE or
                               // SHIFT are asserted.
      .RESET(DMI_RESET),  // 1-bit output: Reset output for TAP controller.
      .RUNTEST(DMI_RUNTEST),   // 1-bit output: Output asserted when TAP controller is in Run Test/Idle state.
      .SEL(DMI_SEL),  // 1-bit output: USER instruction active output.
      .SHIFT(DMI_SHIFT),  // 1-bit output: SHIFT output from TAP controller.
      .TCK(DMI_TCK),  // 1-bit output: Test Clock output. Fabric connection to TAP Clock pin.
      .TDI(DMI_TDI),  // 1-bit output: Test Data Input (TDI) output from TAP controller.
      .TMS(DMI_TMS),  // 1-bit output: Test Mode Select output. Fabric connection to TAP.
      .UPDATE(DMI_UPDATE),  // 1-bit output: UPDATE output from TAP controller

      // Inputs
      .TDO(DMI_TDO)  // 1-bit input: Test Data Output (TDO) input for USER function.
  );











  initial begin
    dtmcs = '{
        zero         : '0,
        errinfo      : 3'h0,  // 0: means not implemented. Reset value is 4. See debug spec
        dtmhardreset : 1'b0,
        dmireset     : 1'b0,
        zero_        : '0,
        idle         : 3'h1,  // 1: Enter Run-Test/Idle and leave it immediately
        dmistat      : 2'h0,  // 0: No error, 2: Op failed, 3: DMI busy
        abits        : DM_REGISTER_SIZE,  // The size of address in dmi
        version      : 4'd1  // Version described in spec version 0.13 (and later?)

    };
    dtmcs_data[DTMCS_DATAWIDTH-1:0] <= dtmcs;

    dm_status = '{
        zero: '0,
        ndmresetpending: 'b0,
        stickyunavail: 'b0,
        impebreak: 'b0,
        zero_: '0,
        allhavereset: 'b0,
        anyhavereset: 'b0,
        allresumeack: 'b0,
        anyresumeack: 'b0,
        allnonexistent: 'b0,
        anynonexistent: 'b0,
        allunavail: 'b0,
        anyunavail: 'b0,
        allrunning: 'b0,
        anyrunning: 'b0,
        allhalted: 'b0,
        anyhalted: 'b0,
        authenticated: 'b1,
        authbusy: 'b0,
        hasresethaltreq: 'b0,
        confstrptrvalid: 'b0,
        version: 'd15  // Debug module conforms to version 1.0
    };

    // logic haltreq,
    // logic resumereq,
    // logic hartreset,
    // logic ackhavereset,
    // logic ackunavail,
    // logic hasel: 'b0,
    // logic [25:16] hartsello: 10'h0,
    // logic [15:6] hartselhi: 10'h0,
    // logic setkeepalive,
    // logic clrkeepalive,
    // logic setresethaltreq,
    // logic clrresethaltreq,
    // logic ndmreset,
    // logic dmactive,  // lsb
    dm_register['h11] <= dm_status;
    dmi_data[DMI_DATAWIDTH-1:0] <= '0;
    dmi_interface_signals.DTM_RSP_READY = 1;  // Ready for reponse as default.
    dmi_interface_signals.DM_REQ_READY = 1;  // Ready for request as default.
    error_out = DMINoError;
    error_in = DMINoError;
    running = 0;
    write_enabled = 1;
  end











  // ########################### DMI ########################### 
  // DMI OVERVIEW EXPLANATION:
  // JTAG state machine runs CAPTURE -> SHIFT -> UPDATE.
  // In UPDATE, the operation should start..
  // In CAPTURE, we capture the data from the requested operation.
  // DMI should not recieve an error during an operation. If we get UPDATE
  // during an operation in progress, we say the DMI is busy. Error is sticky
  // and needs to be reset by the DTMCS dmireset before running next READ/WRITE next request.
  // This is done by writing the appropriate bit in DTMCS, aka USER3 (0x22)

  // TODO: Implement additional cycles in Run-Test/Idle if DMI was busy. Might not be necessary
  // if the requests are handled fast enough.

  // ################ Error handling DMI ################
  always_comb begin
    if (dmi_req.address > DM_REGISTER_SIZE - 1) begin
      //error_in = DMIOpFailed;
    end

    //    if (DMI_UPDATE && running) begin
    //      error_in = DMIBusy;
    //    end

    if (dmi_clear) begin
      dtmcs.errinfo = 3'h0;  // 0: means unimplemented. 4: reset value if implemented.
      error_in = DMINoError;
    end


    dmi_resp.op <= error_in;
    // Propagate the current error into the next iteration
    error_out = error_in;
  end





  // ################ DMI: Request/Response handling ################
  always_comb begin
    if (dmi_clear) begin
      // Should be dtm_clear. It should clear all registers but not implemented.
      // dmi_req <= '0;
      // dmi_resp.address <= '0;
      // dmi_resp.data <= '0;
    end else begin
      if (DMI_UPDATE && DMI_SEL) begin
        dmi_req.address <= dmi_data[DM_REGISTER_SIZE+33:34];
        dmi_req.data <= dmi_data[33:2];
        dmi_req.op <= dmi_data[1:0];

        // Check the previous operation's status. If it succeded, we allow new
        // data to be written/read. Otherwise error is sticky and needs to be
        // reset with dmireset in DTMCS
        unique case (dmi_resp.op)
          DMINoError: begin
            dmi_resp.address = dmi_req.address;
            dmi_resp.data = dm_register[dmi_req.address];
          end

          DMIOpFailed: begin
            dmi_resp.address = dmi_req.address;
            dmi_resp.data = 32'hAAAAAAAA;
            // TODO: Add additional information for dtmcs_err_info
          end

          DMIBusy: begin
            dmi_resp.address = dmi_req.address;
            dmi_resp.data = 32'hBBBBBBBB;
          end

          default: begin
            dmi_resp.address = dmi_req.address;
            dmi_resp.data = 32'hCCCCCCCC;
          end
        endcase

        // Forcing hasel, hasello, haselhi to 0
        // This makes OPENOCD only use 1 hart instead of 1024.
        // If there is a way for Systemverilog to make a field
        // read-only, this can be removed. Don't know how to do
        // this as of now.
        if (dmi_req.op == DMIWrite) begin
          if (dmi_req.address == 6'h10) begin
            dmi_req.data[28:8] <= '0;
          end
        end
      end
    end

  end

  // ################ DMI: Data handling ################
  always @(posedge DMI_TCK) begin
    if (dmi_clear) begin
      dmi_data[DMI_DATAWIDTH-1:0] <= '0;
    end else begin
      // During the CAPTURE event, we catch the response from the requested
      // operation.
      if (DMI_CAPTURE && DMI_SEL) begin
        running = 1;
        unique case (dmi_req.op)
          DMIRead: begin
            dmi_data <= {dmi_resp.address, dmi_resp.data, dmi_resp.op};
          end

          DMIWrite: begin
            dm_register[dmi_req.address] = dmi_req.data;

            // haltreq bit
            if (dmi_req.data[33] == 1) begin
              dm_register['h11][9] <= 1;  // allhalted
            end

            // resumereq bit
            if (dmi_req.data[32] == 1) begin
              dm_register['h11][9]  <= 0;  // allhalted
              dm_register['h11][17] <= 1;  // allresumeack
            end
          end

          // If any other operation then do nothing.
          default: begin
          end
        endcase
      end

      // Shifts in the instruction recieved
      if (DMI_SHIFT && DMI_SEL) begin
        if (dmi_req.op == DMIWrite) begin
          dmi_data <= '0;
        end else begin
          dmi_data <= {DMI_TDI, dmi_data[DMI_DATAWIDTH-1:1]};
        end

      end


      if (DMI_UPDATE && DMI_SEL) begin
        running = 0;
      end
    end

  end



  // ########################### DTMCS ###########################
  //  DTMCS OVERVIEW EXPLANATION:
  //  DTMCS tells the Debugger about the state of transactions. It is
  //  mostly a read register. However, you are able to write to two bits
  //  dmireset and dtmhardreset. Dtmhardreset has not been implemented.
  //  Dmireset resets the dmi_data channel as it should not kill any 
  //  outstanding DMI transactions.



  always @(posedge DTMCS_TCK) begin
    if (DTMCS_UPDATE && DTMCS_SEL) begin
      // dtmcs.errinfo <= 0;
      // NOTE: dtmhardreset might not have to be used. This is
      // used when it expects a DMI transaction to never complete.
      // dtmcs.dtmhardreset <= dtmcs_data[17];
      // TODO: dmireset resets errinfo if implemented.
      dtmcs.dmireset = dtmcs_data[16];
      // TODO: idle should increase if DMIBusy problems occur.
      // dtmcs.idle <= dtmcs_data[14:12];
      dtmcs.dmistat  = dmi_resp.op;
      dtmcs_data <= dtmcs;
    end

    if (DTMCS_CAPTURE && DTMCS_SEL) begin
      dtmcs_data <= dtmcs;
    end

    // Shifts in the instruction recieved
    if (DTMCS_SHIFT && DTMCS_SEL) begin
      dtmcs_data <= {DTMCS_TDI, dtmcs_data[DTMCS_DATAWIDTH-1:1]};
    end

  end


















endmodule
