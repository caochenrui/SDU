`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/14 20:32:06
// Design Name: 
// Module Name: RX
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


module RX(
    input clk,rstn,
    input rxd,rdy_rx,
    output reg [7:0]d_rx,
    // output reg [8:0]temp,
    output vld_rx
    );
reg vld_rx_1;
reg vld_rx_2;
reg [2:0]cs;
reg [2:0]ns;
reg s;
reg [8:0]temp;
reg [3:0]cntc;
reg [3:0]cntb;
parameter Idle=3'b000,Start=3'b001,Bit=3'b010,Shift=3'b011,Save=3'b100;
always @(posedge clk,negedge rstn) begin
    if(!rstn)cs<=Idle;
    else cs<=ns;
end
always @(*) begin
    case (cs)
        Idle:begin
            if(!rxd)ns=Start;
            else ns=Idle;
        end 
        Start:begin
            if(cntc==0)begin
                if(rxd)ns=Idle;
                else ns=Bit;
            end
            else if(!rxd)ns=Start;
            else ns=Idle;
        end
        Bit:begin
            if(cntc==0)ns=Shift;
            else ns=Bit;
        end
        Shift:begin
            if(cntb!=0)ns=Bit;
            else ns=Save;
        end
        Save:begin
            ns=Idle;
        end
        default:begin
            ns=Idle;
        end
    endcase
end
always @(posedge clk) begin
    case (cs)
        Idle:begin
            cntc<=4'd7;
            cntb<=4'd7;
            s<=0;
            temp<=0;
        end 
        Start:begin
            if(ns==Start)cntc<=cntc-1;
            else if(ns==Idle)cntc<=4'd7;
            else cntc<=4'd15;
        end
        Bit:begin
            if(ns==Bit)cntc<=cntc-1;
        end
        Shift:begin
            if(ns==Bit)begin
                cntc<=4'd 15;
                cntb<=cntb-1;
            end
            temp<={rxd,temp[8:1]};
        end
        Save:begin
            s<=1;
            cntc<=4'd7;
            cntb<=4'd8;
        end
        default:begin
            s<=0;
        end
    endcase
end
always @(posedge clk,negedge rstn) begin
    if(!rstn)begin
        vld_rx_1<=0;
    end
    else if(s==1)begin
        if(vld_rx_1==0)begin
            d_rx<={temp[8:1]};
            vld_rx_1<=1;
        end
    end
    else if(vld_rx_1&rdy_rx)vld_rx_1<=0;
end
always @(posedge clk) begin
    vld_rx_2<=vld_rx_1;
end
assign vld_rx=vld_rx_1|vld_rx_2;
endmodule
