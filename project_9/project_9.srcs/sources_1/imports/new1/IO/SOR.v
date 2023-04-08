`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/14 20:08:29
// Design Name: 
// Module Name: SOR
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


module SOR(
    input clk,rstn,
    input [7:0]d_tx,
    input start,
    output txd
    );
reg [8:0]temp;
always @(posedge clk,negedge rstn) begin
    if(!rstn)begin
        temp<=9'b1111_1111_1;
    end
    else if(start)begin
        temp<={d_tx,1'b0};
    end
    else temp<={1'b1,temp[8:1]};
end
assign txd=temp[0];
endmodule
