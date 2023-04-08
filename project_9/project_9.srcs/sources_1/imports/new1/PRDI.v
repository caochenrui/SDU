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
        //input [31:0] npc,pc,ctrl,ir,reg_a,reg_b,imm,branch_y,md,reg_din,ALU_result,
        input [31:0] npc,pc,ir,pcd,
        input [31:0] ire,imm,a,b,pce,ctr,
        input [31:0] irm,mdw,y,ctrm,
        input [31:0] irw,yw,mdr,ctrw, 
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
        GSTR  = 14,
        PSTR  = 15,                    

        P = 2'b00,
        R = 2'b01,
        D = 2'b10,
        I = 2'b11;


    reg [31:0] d_addr , i_addr;     //地址寄存器
    reg [3:0] c_state , n_state, ret_state;
    reg next;     //检测打印是否完成
    reg [5:0] cnt;  //输出计数器
    reg [2:0] str_cnt;  //字符串输出计数器
    reg [10:0] str_addr;
    reg [31:0] data_path;
    wire [7:0] str_path,str_rf;

    reg [7:0]STR_path[0:255];
    reg [7:0]STR_RF[0:255];
    assign str_path = STR_path[str_addr];
    assign str_rf = STR_RF[str_addr];
//32:空格
//48:0
//57:9
//82:R
//97:a
//122:z
    always@(*)begin
        STR_RF[0] = 120;
        STR_RF[1] = 48;
        STR_RF[2] = 48;
        STR_RF[3] = 32;
        STR_RF[4] = 32;
        STR_RF[5] = 120;
        STR_RF[6] = 48;
        STR_RF[7] = 49;
        STR_RF[8] = 32;
        STR_RF[9] = 32;
        STR_RF[10] = 120;
        STR_RF[11] = 48;
        STR_RF[12] = 50;
        STR_RF[13] = 32;
        STR_RF[14] = 32;
        STR_RF[15] = 120;
        STR_RF[16] = 48;
        STR_RF[17] = 51;
        STR_RF[18] = 32;
        STR_RF[19] = 32;
        STR_RF[20] = 120;
        STR_RF[21] = 48;
        STR_RF[22] = 52;
        STR_RF[23] = 32;
        STR_RF[24] = 32;
        STR_RF[25] = 120;
        STR_RF[26] = 48;
        STR_RF[27] = 53;
        STR_RF[28] = 32;
        STR_RF[29] = 32;
        STR_RF[30] = 120;
        STR_RF[31] = 48;
        STR_RF[32] = 54;
        STR_RF[33] = 32;
        STR_RF[34] = 32;
        STR_RF[35] = 120;
        STR_RF[36] = 48;
        STR_RF[37] = 55;
        STR_RF[38] = 32;
        STR_RF[39] = 32;
        STR_RF[40] = 120;
        STR_RF[41] = 48;
        STR_RF[42] = 56;
        STR_RF[43] = 32;
        STR_RF[44] = 32;
        STR_RF[45] = 120;
        STR_RF[46] = 48;
        STR_RF[47] = 57;
        STR_RF[48] = 32;
        STR_RF[49] = 32;
        STR_RF[50] = 120;
        STR_RF[51] = 49;
        STR_RF[52] = 48;
        STR_RF[53] = 32;
        STR_RF[54] = 32;
        STR_RF[55] = 120;
        STR_RF[56] = 49;
        STR_RF[57] = 49;
        STR_RF[58] = 32;
        STR_RF[59] = 32;
        STR_RF[60] = 120;
        STR_RF[61] = 49;
        STR_RF[62] = 50;
        STR_RF[63] = 32;
        STR_RF[64] = 32;
        STR_RF[65] = 120;
        STR_RF[66] = 49;
        STR_RF[67] = 51;
        STR_RF[68] = 32;
        STR_RF[69] = 32;
        STR_RF[70] = 120;
        STR_RF[71] = 49;
        STR_RF[72] = 52;
        STR_RF[73] = 32;
        STR_RF[74] = 32;
        STR_RF[75] = 120;
        STR_RF[76] = 49;
        STR_RF[77] = 53;
        STR_RF[78] = 32;
        STR_RF[79] = 32;
        STR_RF[80] = 120;
        STR_RF[81] = 49;
        STR_RF[82] = 54;
        STR_RF[83] = 32;
        STR_RF[84] = 32;
        STR_RF[85] = 120;
        STR_RF[86] = 49;
        STR_RF[87] = 55;
        STR_RF[88] = 32;
        STR_RF[89] = 32;
        STR_RF[90] = 120;
        STR_RF[91] = 49;
        STR_RF[92] = 56;
        STR_RF[93] = 32;
        STR_RF[94] = 32;
        STR_RF[95] = 120;
        STR_RF[96] = 49;
        STR_RF[97] = 57;
        STR_RF[98] = 32;
        STR_RF[99] = 32;
        STR_RF[100] = 120;
        STR_RF[101] = 50;
        STR_RF[102] = 48;
        STR_RF[103] = 32;
        STR_RF[104] = 32;
        STR_RF[105] = 120;
        STR_RF[106] = 50;
        STR_RF[107] = 49;
        STR_RF[108] = 32;
        STR_RF[109] = 32;
        STR_RF[110] = 120;
        STR_RF[111] = 50;
        STR_RF[112] = 50;
        STR_RF[113] = 32;
        STR_RF[114] = 32;
        STR_RF[115] = 120;
        STR_RF[116] = 50;
        STR_RF[117] = 51;
        STR_RF[118] = 32;
        STR_RF[119] = 32;
        STR_RF[120] = 120;
        STR_RF[121] = 50;
        STR_RF[122] = 52;
        STR_RF[123] = 32;
        STR_RF[124] = 32;
        STR_RF[125] = 120;
        STR_RF[126] = 50;
        STR_RF[127] = 53;
        STR_RF[128] = 32;
        STR_RF[129] = 32;
        STR_RF[130] = 120;
        STR_RF[131] = 50;
        STR_RF[132] = 54;
        STR_RF[133] = 32;
        STR_RF[134] = 32;
        STR_RF[135] = 120;
        STR_RF[136] = 50;
        STR_RF[137] = 55;
        STR_RF[138] = 32;
        STR_RF[139] = 32;
        STR_RF[140] = 120;
        STR_RF[141] = 50;
        STR_RF[142] = 56;
        STR_RF[143] = 32;
        STR_RF[144] = 32;
        STR_RF[145] = 120;
        STR_RF[146] = 50;
        STR_RF[147] = 57;
        STR_RF[148] = 32;
        STR_RF[149] = 32;
        STR_RF[150] = 120;
        STR_RF[151] = 51;
        STR_RF[152] = 48;
        STR_RF[153] = 32;
        STR_RF[154] = 32;
        STR_RF[155] = 120;
        STR_RF[156] = 51;
        STR_RF[157] = 49;
        STR_RF[158] = 32;
        STR_RF[159] = 32;
        
        STR_path[0] = 110;
        STR_path[1] = 112;
        STR_path[2] = 99;
        STR_path[3] = 32;
        STR_path[4] = 9;
        STR_path[5] = 112;
        STR_path[6] = 99;
        STR_path[7] = 32;
        STR_path[8] = 32;
        STR_path[9] = 9;
        STR_path[10] = 105;
        STR_path[11] = 114;
        STR_path[12] = 32;
        STR_path[13] = 32;
        STR_path[14] = 9;
        STR_path[15] = 112;
        STR_path[16] = 99;
        STR_path[17] = 100;
        STR_path[18] = 32;
        STR_path[19] = 9;
        STR_path[20] = 105;
        STR_path[21] = 114;
        STR_path[22] = 101;
        STR_path[23] = 32;
        STR_path[24] = 9;
        STR_path[25] = 105;
        STR_path[26] = 109;
        STR_path[27] = 109;
        STR_path[28] = 32;
        STR_path[29] = 9;
        STR_path[30] = 97;
        STR_path[31] = 32;
        STR_path[32] = 32;
        STR_path[33] = 32;
        STR_path[34] = 9;
        STR_path[35] = 98;
        STR_path[36] = 32;
        STR_path[37] = 32;
        STR_path[38] = 32;
        STR_path[39] = 9;
        STR_path[40] = 112;
        STR_path[41] = 99;
        STR_path[42] = 101;
        STR_path[43] = 32;
        STR_path[44] = 9;
        STR_path[45] = 99;
        STR_path[46] = 116;
        STR_path[47] = 114;
        STR_path[48] = 32;
        STR_path[49] = 9;
        STR_path[50] = 105;
        STR_path[51] = 114;
        STR_path[52] = 109;
        STR_path[53] = 32;
        STR_path[54] = 9;
        STR_path[55] = 109;
        STR_path[56] = 100;
        STR_path[57] = 119;
        STR_path[58] = 32;
        STR_path[59] = 9;
        STR_path[60] = 121;
        STR_path[61] = 32;
        STR_path[62] = 32;
        STR_path[63] = 32;
        STR_path[64] = 9;
        STR_path[65] = 99;
        STR_path[66] = 116;
        STR_path[67] = 114;
        STR_path[68] = 109;
        STR_path[69] = 9;
        STR_path[70] = 105;
        STR_path[71] = 114;
        STR_path[72] = 119;
        STR_path[73] = 32;
        STR_path[74] = 9;
        STR_path[75] = 121;
        STR_path[76] = 119;
        STR_path[77] = 32;
        STR_path[78] = 32;
        STR_path[79] = 9;
        STR_path[80] = 109;
        STR_path[81] = 100;
        STR_path[82] = 114;
        STR_path[83] = 32;
        STR_path[84] = 9;
        STR_path[85] = 99;
        STR_path[86] = 116;
        STR_path[87] = 114;
        STR_path[88] = 119;
        STR_path[89] = 9;
    end

    always@(*) begin
        case (addr_out)
            0:
            data_path = npc;
            1:
            data_path = pc;
            2:
            data_path = ir;
            3:
            data_path = pcd;
            4:
            data_path = ire;
            5:
            data_path = imm;
            6:
            data_path = a;
            7:
            data_path = b;
            8:
            data_path = pce;
            9:
            data_path = ctr;
            10:
            data_path = irm;
            11:
            data_path = mdw;
            12:
            data_path = y;
            13:
            data_path = ctrm;
            14:
            data_path = irw;
            15:
            data_path = yw;
            16:
            data_path = mdr;
            17:
            data_path = ctrw;
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
                n_state = GSTR;
            RS: 
                n_state = GSTR;
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
            GSTR:
                n_state = PSTR;
            PSTR:
                begin
                    if(next) begin
                        n_state = PRINT;
                    end
                    else begin
                        n_state = PSTR;
                    end
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
            str_cnt <= 0;
            str_addr <= 0;
        end
        else begin
            c_state <= n_state;
            case (c_state)
                FREE:
                    if(exe)
                        PRDI_busy <= 1;
                    else
                        PRDI_busy <= 0;
                START: begin
                    str_addr <= 0;
                    str_cnt <= 5;
                    PRDI_busy <= 1;
                end
                PS:
                    begin
                        cnt <= 18;
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
                            if(cnt > 0) begin
                                if(mode == D || mode == I)
                                    ret_state <= GDATA;
                                else begin
                                    ret_state <= GSTR;
                                    str_cnt <= 5;
                                end
                            end
                            else
                                ret_state <= OVER;
                        end
                    end
                GSTR:
                    begin
                        str_cnt <= str_cnt - 1;
                        if(mode == P)
                            dout_tx <= str_path;
                        else if(mode == R)
                            dout_tx <= str_rf;
                        else if(mode == D)
                            dout_tx <= 0;
                        else if(mode == I)
                            dout_tx <= 0;
                    end
                PSTR:
                    begin
                        type_tx <= 0;
                        if(print_busy == 0) begin
                            next <= 1;
                            req_tx <= 1;
                            if(next == 1)
                                str_addr <= str_addr + 1;
                            if(str_cnt > 0) begin
                                ret_state <= GSTR;
                            end
                            else
                                ret_state <= GDATA;
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