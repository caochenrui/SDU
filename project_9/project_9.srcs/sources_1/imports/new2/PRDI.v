`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/17 09:43:07
// Design Name: 
// Module Name: PRDI
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


module PRDI(
        input clk,rstn,
        input exe,          //开始执行
        input [31:0] addr_in,   //传进来的修改地址
        input [1:0] mode,         //模式:00_P , 01_R , 10_D , 11_I
        input enable,       //写使能
        output reg PRDI_busy,   //本模块的busy

        //与打印模块的对接
        input print_busy,
        output reg [31:0] dout_tx,
        output reg type_tx,
        output reg req_tx,

        //与CPU存储器的对接,传出addr_out,送进来4个相应的内容
        output reg [31:0] addr_out,
        input [31:0] npc,pc,ctrl,ir,reg_a,reg_b,imm,branch_y,md,reg_din,ALU_result,
        input [31:0] dout_rf,
        input [31:0] dout_dm,
        input [31:0] dout_im
    );
    parameter FREE = 0,
        START = 1,
        PS = 2,
        RS = 3,
        DS = 4,
        IS = 5,
        PD = 6,
        PI = 7,
        PN = 8,
        PADDR = 9,
        GDATA = 10,
        PDATA = 11,
        OVER = 12,
        PRINT = 13,         //打印状态，检测到busy为0时跳到此状态，直到busy为1时req清掉跳回返回地址
                            

        P = 2'b00,
        R = 2'b01,
        D = 2'b10,
        I = 2'b11;


    reg [31:0] d_addr , i_addr;     //地址寄存器
    reg [3:0] c_state , n_state, ret_state;
    reg next;     //检测打印是否完成
    reg [5:0] cnt;  //输出计数器
    reg [31:0] data_path;

    always@(*) begin
        case (addr_out)
            0:
            data_path = npc;
            1:
            data_path = pc;
            2:
            data_path = ctrl;
            3:
            data_path = ir;
            4:
            data_path = reg_a;
            5:
            data_path = reg_b;
            6:
            data_path = imm;
            7:
            data_path = branch_y;
            8:
            data_path = md;
            9:
            data_path = reg_din;
            10:
            data_path = ALU_result;
            default: 
            data_path = 0;
        endcase
    end

    always@(*) begin
        case (c_state)
            FREE:
                begin
                    if(exe)
                        n_state = START;
                    else
                        n_state = FREE;
                end
            START:
                begin
                    if(mode == P)
                        n_state = PS;
                    else if(mode == R)
                        n_state = RS;
                    else if(mode == D)
                        n_state = DS;
                    else if(mode == I)
                        n_state = IS;
                    else
                        n_state = START;
                end
            PS:
                n_state = GDATA;
            RS: 
                n_state = GDATA;
            DS:
                n_state = PD;
            IS:
                n_state = PI;
            PD:
                begin
                    if(next)
                        n_state = PRINT;
                    else
                        n_state = PD;
                end
            PI:
                begin
                    if(next)
                        n_state = PRINT;
                    else
                        n_state = PI;
                end
            PN:
                begin
                    if(next)
                        n_state = PRINT;
                    else
                        n_state = PN;
                end
            PADDR:
                begin
                    if(next)
                        n_state = PRINT;
                    else
                        n_state = PADDR;
                end
            GDATA:
                n_state = PDATA;
            PDATA:
                begin
                    if(next) begin
                        n_state = PRINT;
                    end
                    else
                        n_state = PDATA;
                end
            OVER:
                begin
                    if(next)
                        n_state = PRINT;
                    else
                        n_state = OVER;
                end
            PRINT:
                begin
                    if(print_busy)
                        n_state = ret_state;
                    else
                        n_state = PRINT;
                end
            default: 
                n_state = FREE;
        endcase

    end

    always @(posedge clk , negedge rstn) begin
        if(!rstn) begin
            PRDI_busy <= 0;
            dout_tx <= 0;
            type_tx <= 0;
            req_tx <= 0;
            addr_out <= 0;
            d_addr <= 0;
            i_addr <= 0;
            c_state <= 0;
            ret_state <= 0;
            next <= 0;
        end
        else begin
            c_state <= n_state;
            case (c_state)
                FREE:
                    if(exe)
                        PRDI_busy <= 1;
                    else
                        PRDI_busy <= 0;
                START:
                    PRDI_busy <= 1;
                PS:
                    begin
                        cnt <= 11;
                        addr_out <= 0;
                    end
                RS: 
                    begin
                        cnt <= 32;
                        addr_out <= 0;
                    end
                DS:
                    begin
                        cnt <= 8;
                        if(enable) begin
                            d_addr <= addr_in + 8;     //保存输出结束后地�?
                            addr_out <= addr_in;
                        end
                        else begin
                            addr_out <= d_addr;
                            d_addr <= d_addr + 8;      //保存输出结束后地�?
                        end
                    end
                IS:
                    begin
                        cnt <= 8;
                        if(enable) begin
                            i_addr <= addr_in + 8;     //保存输出结束后地�?
                            addr_out <= addr_in;
                        end
                        else begin
                            addr_out <= i_addr;
                            i_addr <= i_addr + 8;      //保存输出结束后地�?
                        end
                    end
                PD:
                    begin
                        dout_tx <= 68;          //print 'D'
                        type_tx <= 0;
                        if(print_busy == 0) begin
                            next <= 1;
                            req_tx <= 1;
                            ret_state <= PN;
                        end
                    end
                PI:
                    begin
                        dout_tx <= 73;          //print 'I'
                        type_tx <= 0;
                        if(print_busy == 0) begin
                            next <= 1;
                            req_tx <= 1;
                            ret_state <= PN;
                        end
                    end
                PN:
                    begin
                        dout_tx <= 45;          //print '-'
                        type_tx <= 0;
                        //req_tx <= 1;
                        if(print_busy == 0) begin
                            next <= 1;
                            req_tx <= 1;
                            ret_state <= PADDR;
                        end
                    end
                PADDR:
                    begin
                        dout_tx <= addr_out;          //print current address
                        type_tx <= 1;
                        if(print_busy == 0) begin
                            next <= 1;
                            req_tx <= 1;
                            ret_state <= GDATA;
                        end
                    end
                GDATA:
                    begin
                        cnt <= cnt - 1;
                        if(mode == P)
                            dout_tx <= data_path;
                        else if(mode == R)
                            dout_tx <= dout_rf;
                        else if(mode == D)
                            dout_tx <= dout_dm;
                        else if(mode == I)
                            dout_tx <= dout_im;
                    end
                PDATA:
                    begin
                        type_tx <= 1;
                        if(print_busy == 0) begin
                            next <= 1;
                            req_tx <= 1;
                            if(next == 1)
                                addr_out <= addr_out + 1;
                            ret_state <= PADDR;
                            if(cnt > 0) 
                                ret_state <= GDATA;
                            else
                                ret_state <= OVER;
                        end
                    end
                PRINT:
                    begin
                        if(print_busy == 1) begin
                            req_tx<=0;
                            next<=0;
                        end
                    end
                OVER:
                    begin
                        dout_tx <= 10;          //print '\n'
                        type_tx <= 0;
                        //req_tx <= 1;
                        if(print_busy == 0) begin
                            next <= 1;
                            req_tx <= 1;
                            ret_state <= FREE;
                        end
                    end
            endcase

        end
    end

endmodule        