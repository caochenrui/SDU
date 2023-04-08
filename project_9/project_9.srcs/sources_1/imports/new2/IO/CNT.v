`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/14 20:23:19
// Design Name: 
// Module Name: CNT
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


module CNT#(parameter A = 4'd8)(
    input clk,rstn,
    input pe,
    output reg [3:0]cnt
    );
always @(posedge clk,negedge rstn) begin
    if(!rstn)begin
        cnt<=0;
    end
    else if(pe)cnt<=A;
    else if(cnt)cnt<=cnt-1;
end
endmodule
