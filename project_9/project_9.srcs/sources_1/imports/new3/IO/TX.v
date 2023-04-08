`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/14 19:58:59
// Design Name: 
// Module Name: TX
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


module TX(
    input clk,rstn,
    input [7:0]d_tx,
    input vld_tx,
    // output [8:0]temp,
    output txd,rdy_tx
    );
wire en;
wire [3:0]cnt;
assign en=vld_tx&rdy_tx;
SOR SOR(
    // .temp(temp),
    .clk(clk),
    .rstn(rstn),
    .d_tx(d_tx),
    .txd(txd),
    .start(en)
);
CNT CNT(
    .clk(clk),
    .rstn(rstn),
    .pe(en),
    .cnt(cnt)
);
RDY RDY(
    .rstn(rstn),
    .clk(clk),
    .vld_tx(vld_tx),
    .cnt(cnt),
    .rdy_tx(rdy_tx)
);
endmodule
