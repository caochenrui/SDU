`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/18 13:54:25
// Design Name: 
// Module Name: I_O
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module I_O(
    output [2:0]scan_state,
    input clk_rx,clk_tx,rstn,
    input rxd,
    output txd,

    input scan_stop,
    output [31:0]din_rx,
    output flag_rx,bsy_rx,
    input req_rx,type_rx,

    output bsy_tx,
    input [31:0]dout_tx,
    input req_tx,type_tx
    );
wire [7:0]d_rx;
wire [7:0]d_tx;
// wire [15:0]check;
wire vld_rx,rdy_rx,vld_tx,rdy_tx;
// wire [31:0]din_rx;
// assign din_rx1={8'd0,d_rx};

SCAN SCAN(
    // .check(check),
    .scan_state(scan_state),
    .scan_stop(scan_stop),
    .din_rx(din_rx),
    .flag_rx(flag_rx),
    .type_rx(type_rx),
    .req_rx(req_rx),
    .bsy_rx(bsy_rx),
    .d_rx(d_rx),
    .vld_rx(vld_rx),
    .rdy_rx(rdy_rx),
    .clk(clk_rx),
    .rstn(rstn)
);
PRINT PRINT(
    .dout_tx(dout_tx),
    .type_tx(type_tx),
    .req_tx(req_tx),
    .bsy_tx(bsy_tx),
    .d_tx(d_tx),
    .vld_tx(vld_tx),
    .rdy_tx(rdy_tx),
    .clk(clk_tx),
    .rstn(rstn)
);
RX RX(
    .d_rx(d_rx),
    .vld_rx(vld_rx),
    .rdy_rx(rdy_rx),
    .rxd(rxd),
    .clk(clk_rx),
    .rstn(rstn)
);
TX TX(
    .d_tx(d_tx),
    .vld_tx(vld_tx),
    .rdy_tx(rdy_tx),
    .txd(txd),
    .clk(clk_tx),
    .rstn(rstn)
);
endmodule
