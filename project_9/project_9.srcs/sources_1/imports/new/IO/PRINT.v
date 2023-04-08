`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/16 21:52:41
// Design Name: 
// Module Name: PRINT
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


module PRINT(
    input [31:0]dout_tx,
    input type_tx,req_tx,
    output reg bsy_tx,
    output reg [7:0]d_tx,
    output reg vld_tx,
    input rdy_tx,

    input clk,rstn
    );
parameter Idle=3'b000,word=3'b001,OK1=3'b010,byte=3'b011,OK2=3'b100,complete=3'b101;
reg [3:0]cnt;
reg [2:0]cs;
reg [2:0]ns;
reg [7:0]ascii;

reg [31:0]dout_tx_reg;

always @(posedge clk,negedge rstn) begin
    if(!rstn)cs<=Idle;
    else cs<=ns;
end
always @(*) begin
    case (cs)
        Idle:begin
            if(req_tx)begin
                if(type_tx)ns=word;
                else ns=byte;
            end
            else ns=Idle;
        end
        word:begin
            if(rdy_tx)ns=OK1;
            else ns=word;
        end
        OK1:begin
            if(cnt==4'd9)ns=complete;
            else ns=word;
        end
        byte:begin
            if(rdy_tx)ns=OK2;
            else ns=byte;
        end
        OK2:begin
            ns=complete;
        end
        complete:begin
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
            if(ns!=Idle)begin
                bsy_tx<=1;
                cnt<=0;
                dout_tx_reg<=dout_tx;
            end
        end
        word:begin
            d_tx<=ascii;
            vld_tx<=1;
        end
        OK1:begin
            vld_tx<=0;
            cnt<=cnt+1;
        end
        byte:begin
            d_tx<=dout_tx_reg[7:0];
            vld_tx<=1;
        end
        OK2:begin
            vld_tx<=0;
        end
        complete:begin
            bsy_tx<=0;
        end
        default:begin

        end 
    endcase
end
always @(*) begin
    case (cnt)
        4'd7:ascii=(dout_tx_reg[3:0]>=4'd10)?({4'b0000,dout_tx_reg[3:0]}+8'd55):({4'b0000,dout_tx_reg[3:0]}+8'd48);
        4'd6:ascii=(dout_tx_reg[7:4]>=4'd10)?({4'b0000,dout_tx_reg[7:4]}+8'd55):({4'b0000,dout_tx_reg[7:4]}+8'd48);
        4'd5:ascii=(dout_tx_reg[11:8]>=4'd10)?({4'b0000,dout_tx_reg[11:8]}+8'd55):({4'b0000,dout_tx_reg[11:8]}+8'd48); 
        4'd4:ascii=(dout_tx_reg[15:12]>=4'd10)?({4'b0000,dout_tx_reg[15:12]}+8'd55):({4'b0000,dout_tx_reg[15:12]}+8'd48);  
        4'd3:ascii=(dout_tx_reg[19:16]>=4'd10)?({4'b0000,dout_tx_reg[19:16]}+8'd55):({4'b0000,dout_tx_reg[19:16]}+8'd48); 
        4'd2:ascii=(dout_tx_reg[23:20]>=4'd10)?({4'b0000,dout_tx_reg[23:20]}+8'd55):({4'b0000,dout_tx_reg[23:20]}+8'd48);
        4'd1:ascii=(dout_tx_reg[27:24]>=4'd10)?({4'b0000,dout_tx_reg[27:24]}+8'd55):({4'b0000,dout_tx_reg[27:24]}+8'd48); 
        4'd0:ascii=(dout_tx_reg[31:28]>=4'd10)?({4'b0000,dout_tx_reg[31:28]}+8'd55):({4'b0000,dout_tx_reg[31:28]}+8'd48); 
        4'd8:ascii=8'h0D;
        4'd9:ascii=8'h0A;
        default: ascii=8'h00;
    endcase
end
endmodule
