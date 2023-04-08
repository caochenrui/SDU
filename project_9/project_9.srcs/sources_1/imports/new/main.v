`timescale 1ns / 1ps

module main(
    output [15:0]LED,
    input clk,
    input rstn,
    input rxd,
    output txd
);

wire [3:0]check;
wire busy;
wire [2:0]scan_state;
// wire [9:0]check1;
assign LED={scan_state,busy,8'b0,check};
wire clk_cpu,we_dm,we_im,clk_ld,ld;
wire [31:0]pc_chk,npc,pc,addr,dout_rf,dout_dm,dout_im,din;
wire [31:0]ir,pcd,ire,imm,a,b,pce,ctr,irm,mdw,y,ctrm,irw,yw,ctrw,mdr;


Serial_Debug_Unit(.pc_chk(pc_chk),.scan_state(scan_state),.busy(busy),.check(check),
.clk(clk),.rstn(rstn),.rxd(rxd),.txd(txd),.clk_cpu(clk_cpu),.ld(ld),
.addr(addr),.dout_rf(dout_rf),.dout_dm(dout_dm),.dout_im(dout_im),.din(din),.we_dm(we_dm),.we_im(we_im),.clk_ld(clk_ld),
.npc(npc),.pc(pc),.ir(ir),.pcd(pcd),.mdr(mdr),
.ire(ire),.imm(imm),.a(a),.b(b),.pce(pce),.ctr(ctr),
.irm(irm),.mdw(mdw),.y(y),.ctrm(ctrm),
.irw(irw),.yw(yw),.ctrw(ctrw)
);

CPU(.pc_chk(pc_chk),.clk_ld(clk_ld),.rstn(rstn),.clk_cpu(clk_cpu),
.addr(addr),.dout_rf(dout_rf),.dout_dm(dout_dm),.dout_im(dout_im),.din(din),.we_dm(we_dm),.we_im(we_im),.ld(ld),
.npc(npc),.pc(pc),.ir(ir),.pcd(pcd),.mdr(mdr),
.ire(ire),.imm(imm),.a(a),.b(b),.pce(pce),.ctr(ctr),
.irm(irm),.mdw(mdw),.y(y),.ctrm(ctrm),
.irw(irw),.yw(yw),.ctrw(ctrw)
);

endmodule
