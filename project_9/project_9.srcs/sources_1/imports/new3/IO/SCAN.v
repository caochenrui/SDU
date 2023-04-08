`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/16 21:49:48
// Design Name: 
// Module Name: SCAN
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


module SCAN(
    output [2:0]scan_state,
    output reg [31:0]din_rx,
    output reg flag_rx,
    input scan_stop,
    input type_rx,req_rx,
    output reg bsy_rx,

    input [7:0]d_rx,
    input vld_rx,
    output reg rdy_rx,
    // output reg [15:0]check,

    input clk,rstn
    );
parameter Idle=3'b000,word=3'b001,OK1=3'b010,byte=3'b011,OK2=3'b100,complete=3'b101,space=3'b110;
// reg [15:0]check1;
reg [7:0]last;
reg [3:0]cnt;
reg [2:0]cs;
reg [2:0]ns;
reg [3:0]hex;

assign scan_state[2:0]=cs[2:0];

always @(posedge clk,negedge rstn) begin
    if(!rstn)cs<=Idle;
    else cs<=ns;
end
always @(*) begin
    case (cs)
        Idle:begin
            if(req_rx)begin
                if(type_rx)ns=word;
                else ns=byte;
            end
            else ns=Idle;
        end
        word:begin
            if(vld_rx&rdy_rx)ns=OK1;
            else ns=word;
        end
        OK1:begin
            if(last!=8'h0D)ns=word;
            else ns=complete;
        end
        byte:begin
            if(scan_stop)ns=Idle;
            else if(vld_rx&rdy_rx)ns=OK2;
            else ns=byte;
        end
        OK2:begin
            ns=complete;
        end
        complete:begin
            ns=space;
        end
        space:begin
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
                last<=0;
                bsy_rx<=1;
                din_rx<=0;
                cnt<=0;
                rdy_rx<=0;
            end
            else bsy_rx<=0;
        end
        word:begin
            rdy_rx<=1;
        end
        OK1:begin
            rdy_rx<=0;
            if(d_rx!=8'h0A&&d_rx!=8'h0D)begin
                din_rx<={din_rx[27:0],hex};
                cnt<=cnt+1;
            end
            last<=d_rx;
            if(ns==complete)begin
                if(cnt)flag_rx<=0;
                else flag_rx<=1;//空数据
            end
        end
        byte:begin
            rdy_rx<=1;
        end
        OK2:begin
            rdy_rx<=0;
            din_rx<={24'd0,d_rx};
            flag_rx<=0;
        end
        complete:begin
            bsy_rx<=0;
            // check<=check1;
        end
        space:begin
            
        end
        default:begin

        end 
    endcase
end
always @(*) begin
    case (d_rx)
        8'd48:hex=4'd0;
        8'd49:hex=4'd1;
        8'd50:hex=4'd2;
        8'd51:hex=4'd3;
        8'd52:hex=4'd4;
        8'd53:hex=4'd5;
        8'd54:hex=4'd6;
        8'd55:hex=4'd7;
        8'd56:hex=4'd8;
        8'd57:hex=4'd9;
        8'd65:hex=4'd10;
        8'd66:hex=4'd11;
        8'd67:hex=4'd12;
        8'd68:hex=4'd13;
        8'd69:hex=4'd14;
        8'd70:hex=4'd15;
        8'd97:hex=4'd10;
        8'd98:hex=4'd11;
        8'd99:hex=4'd12;
        8'd100:hex=4'd13;
        8'd101:hex=4'd14;
        8'd102:hex=4'd15;
        default:hex=4'd0;
    endcase
end
endmodule