`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/14 20:02:49
// Design Name: 
// Module Name: RDY
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


module RDY(
    input rstn,clk,
    input vld_tx,
    input [3:0]cnt,
    output reg rdy_tx
    );
always @(posedge clk,negedge rstn) begin
    if(!rstn)begin
        rdy_tx<=1;
    end
    else begin
        if(vld_tx&rdy_tx)rdy_tx<=0;
        else if(cnt==0)rdy_tx<=1;
    end
end
endmodule
