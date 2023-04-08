`timescale 1ns / 1ps

module main(
    output [15:0]LED,
    input clk,
    input rstn,
    input rxd,
    output txd
);

wire [5:0]check;
wire busy;
wire [2:0]scan_state;
wire [9:0]check1;
assign LED={scan_state,check1[5:0],busy,check};
wire clk_cpu,we_dm,we_im,clk_ld,ld;
wire [31:0]pc_chk,npc,pc,addr,dout_rf,dout_dm,dout_im,din;
wire [31:0]ctrl,ir,reg_a,reg_b,imm,branch_y,md,reg_din,ALU_result;

Serial_Debug_Unit(.pc_chk(pc_chk),.scan_state(scan_state),.busy(busy),.check1(check1),.check(check),.clk(clk),.rstn(rstn),.rxd(rxd),.txd(txd),.clk_cpu(clk_cpu),.npc(npc),.pc(pc),.ld(ld),.addr(addr),.dout_rf(dout_rf),.dout_dm(dout_dm),.dout_im(dout_im),.din(din),.we_dm(we_dm),.we_im(we_im),.clk_ld(clk_ld),.ctrl(ctrl),.ir(ir),.reg_a(reg_a),.reg_b(reg_b),.imm(imm),.branch_y(branch_y),.md(md),.reg_din(reg_din),.ALU_result(ALU_result));

CPU(.pc_chk(pc_chk),.clk_ld(clk_ld),.rstn(rstn),.clk_cpu(clk_cpu),.npc(npc),.pc(pc),.addr(addr),.dout_rf(dout_rf),.dout_dm(dout_dm),.dout_im(dout_im),.din(din),.we_dm(we_dm),.we_im(we_im),.ctr(ctrl),.ir(ir),.a(reg_a),.b(reg_b),.imm(imm),.yw(branch_y),.mdw(md),.pce(reg_din),.y(ALU_result));

endmodule
