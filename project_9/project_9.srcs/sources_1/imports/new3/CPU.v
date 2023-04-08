`timescale 1ns / 1ps

module CPU(
    input clk_cpu,
    input clk_ld,
    input rstn,
    input ld,
    input [31:0]addr,
    output [31:0]dout_rf,
    output [31:0]dout_dm,
    output [31:0]dout_im,
    input [31:0]din,
    input we_dm,
    input we_im,
    output [31:0]npc,pc_chk,
    output reg [31:0]pc,pce,ir,a,b,pcd,ire,imm,y,yw,irw,irm,mdw,
    output reg [32:1]ctr,ctrm,ctrw
);

    wire zero;
    reg fstall,dstall,eflush,dflush;
    reg [2:0]type;//R I S SB UJ U
    reg [32:1]ctrd;//pcmux,writedata,alu1,branch,memread,mentoreg,[4:1]aluop,memwrite,alusrc,regwrite
    reg [31:0]immd,mdr,aluresult,rd,rdm,rdw,rs1,rs2,bb,aa;
    wire [31:0]irf,alu2,alu1,readdata1,readdata2,writedata,readdata;
    reg [31:0]rf[0:31];
    assign pc_chk=pce;  

    //MUX PC
    assign npc=ctr[13]?(writedata&~1):((zero&ctr[10])?(pce+imm):(pc+4));
    //MUX WD
    assign writedata=ctrw[8]?mdr:yw;
    //MUX ALU2
    assign alu2=ctr[2]?imm:bb;
    //MUX ALU1
    assign alu1=ctr[11]?pc:aa;
    // assign alu1=aa;
    //PC
    always @(posedge clk_cpu,negedge rstn) begin
        if(!rstn) pc<='h00003000;
        else if(!fstall) pc<=npc;
    end
    //IF/ID
    always @(posedge clk_cpu,negedge rstn) begin
        if(!rstn|dflush) begin pcd<=0;ir<=0;end
        else if(!dstall) begin pcd<=pc;ir<=irf; end
    end
    //ID/EX
    always @(posedge clk_cpu,negedge rstn) begin
        if(!rstn|eflush) begin ctr<=0;pce<=0;a<=0;b<=0;imm<=0;ire<=0;rs1<=0;rs2<=0;rd<=0; end
        else begin ctr<=ctrd;pce<=pcd;a<=readdata1;b<=readdata2;imm<=immd;ire<=ir;rs1<=ir[19:15];rs2<=ir[24:20];rd<=ir[11:7]; end
        // if (!rstn|eflush) ctr<=0;//???
        // else ctr<=ctrd;
    end
    //EX/MEM
    always @(posedge clk_cpu,negedge rstn) begin
        if(!rstn) begin ctrm<=0;y<=0;mdw<=0;irm<=0;rdm<=0; end
        else begin ctrm<=ctr;y<=aluresult;mdw<=b;irm<=ire;rdm<=rd; end
    end
    //MEM/WB
    always @(posedge clk_cpu,negedge rstn) begin
        if(!rstn) begin ctrw<=0;mdr<=0;yw<=0;irw<=0;rdw<=0; end
        else begin ctrw<=ctrm;mdr<=readdata;yw<=y;irw<=irm;rdw<=rdm; end
    end
    //IM
    dist_mem_gen_0(
        .a(addr),        // input wire [9 : 0] a
        .d(din),        // input wire [31 : 0] d
        .dpra((pc-'h00003000)>>2),  // input wire [9 : 0] dpra
        .clk(clk_ld),    // input wire clk
        .we(we_im),      // input wire we
        .spo(dout_im),    // output wire [31 : 0] spo
        .dpo(irf)    // output wire [31 : 0] dpo
    );
    //DM
    wire [31:0]dpo1,spo1;
    dist_mem_gen_1(
        .a(we_dm?addr:y>>2),        // input wire [9 : 0] a
        .d(we_dm?din:mdw),        // input wire [31 : 0] d
        .dpra(we_dm?y>>2:addr),  // input wire [9 : 0] dpra
        .clk(clk_ld),    // input wire clk
        .we(we_dm|ctrm[3]),      // input wire we
        .spo(spo1),    // output wire [31 : 0] spo
        .dpo(dpo1)    // output wire [31 : 0] dpo
    );
    assign dout_dm=we_dm?spo1:dpo1;
    assign readdata=ctrm[9]?(we_dm?dpo1:spo1):0;
    //RF
    always @(posedge clk_cpu,negedge rstn) begin:RF
        integer i;
        if(!rstn) for (i=0;i<32;i=i+1) rf[i]<=0;
        else if(ctrw[1]) rf[irw[11:7]]<=writedata;
    end
    assign dout_rf=(addr==0)?0:rf[addr];
    assign readdata1=(ir[19:15]==irw[11:7])?(writedata):(ir[19:15]==0)?0:rf[ir[19:15]];
    assign readdata2=(ir[24:20]==irw[11:7])?(writedata):(ir[24:20]==0)?0:rf[ir[24:20]];
    //CONTROL
    always @(*) begin
        case (ir[6:0])
            'b0110011:  case (ir[14:12])
                            'b000:case (ir[30])
                                    'b0: begin ctrd='b000000_0010_001;type=1; end//add
                                    'b1: begin ctrd='b000000_0110_001;type=1; end//sub
                                endcase
                            // 'b001: 
                            // 'b010:
                            // 'b011: 
                            'b100: begin ctrd='b000000_0011_001;type=1; end//xor
                            // 'b101: 
                            'b110: begin ctrd='b000000_0001_001;type=1; end//or
                            'b111: begin ctrd='b000000_0000_001;type=1; end//and
                            default: begin ctrd=0;type=1; end
                        endcase 
            'b0000011: case (ir[14:12])
                            // 'b000:
                            // 'b001: 
                            'b010: begin ctrd='b000011_0010_011;type=2; end//lw
                            // 'b011: 
                            // 'b100: 
                            // 'b101: 
                            // 'b110:
                            // 'b111:
                            default: begin ctrd=0;type=2; end
                        endcase 
            'b0010011: case (ir[14:12])
                            'b000: begin ctrd='b000000_0010_011;type=2; end//addi
                            'b001: begin ctrd='b000011_0101_001;type=2; end//slli
                            // 'b010:
                            // 'b011: 
                            // 'b100: 
                            'b101: case (ir[30])
                                    'b0: begin ctrd='b000000_1001_001;type=2; end//srli
                                    'b1: begin ctrd='b000000_1010_001;type=2; end//srai
                                endcase
                            // 'b110: 
                            // 'b111: 
                            default: begin ctrd=0;type=2; end
                        endcase
            'b1100111: begin ctrd='b110100_0010_001;type=2; end//jalr
            'b1100011: case (ir[14:12])
                            'b000: begin ctrd='b000100_0110_000;type=4; end//beq
                            // 'b001://bne 
                            // 'b010:
                            // 'b011: 
                            'b100: begin ctrd='b000100_0111_000;type=4; end//blt
                            // 'b101:
                            'b110: begin ctrd='b000100_1000_000;type=4; end//bltu
                            // 'b111: 
                            default: begin ctrd=0;type=4; end
                        endcase
            'b0100011: case (ir[14:12])
                            // 'b000:
                            // 'b001:
                            'b010: begin ctrd='b000000_0010_110;type=3; end//sw
                            // 'b111: 
                            default: begin ctrd=0;type=3; end
                        endcase
            'b0110111: begin ctrd='b000000_0100_011;type=6; end//lui
            'b0010111: begin ctrd='b001000_0010_011;type=6; end//auipc
            'b1101111: begin ctrd='b010100_1011_001;type=5; end//jal
            default: begin ctrd=0;type=0; end
        endcase
    end
    //IMMGEN
    always @(*) begin
        case (type)
            // 1: immd=;
            2: immd={{20{ir[31]}},ir[31:20]};
            3: immd={{20{ir[31]}},ir[31:25],ir[11:7]};
            4: immd={{19{ir[31]}},ir[31],ir[7],ir[30:25],ir[11:8],1'b0};
            5: immd={{11{ir[31]}},ir[31],ir[19:12],ir[20],ir[30:21],1'b0};
            6: immd=ir[31:12]<<12;
            default: immd=0;
        endcase
    end
    //ALU
    always @(*) begin
        case (ctr[7:4])
            0:aluresult=alu1&alu2;//0000
            1:aluresult=alu1|alu2;//0001
            2:aluresult=alu1+alu2;//0010
            3:aluresult=alu1^alu2;//0011
            4:aluresult=alu2;//0100
            5:aluresult=alu1<<alu2;//0101
            6:aluresult=alu1-alu2;//0110
            7:aluresult=$signed(alu1)<$signed(alu2)?0:1;//0111
            8:aluresult=alu1<alu2?0:1;//1000
            9:aluresult=alu1>>alu2;//1001
            10:aluresult=alu1>>>alu2;//1010
            11:aluresult=0;//1011
            12:aluresult=~(alu1|alu2);//1100
            default: aluresult=0;
        endcase
    end
    assign zero=(aluresult==0?1:0);
    //FU
    // wire [1:0]afwd,bfwd;
    always @(*) begin
        if ((ctrm[1])&(rdm==rs1)) aa=y;//write, ctrm first
        else if ((ctrw[1])&(rdw==rs1)) aa=writedata;
        else aa=a;
        if ((ctrm[1])&(rdm==rs2)) bb=y;//write, ctrm first
        else if ((ctrw[1])&(rdw==rs2)) bb=writedata;
        else bb=b;
    end
    //HDU
    always @(*) begin//LU
        if((rd==ir[19:15]|rd==ir[24:20])&ctr[9]) begin dstall=1;fstall=1;end
        else begin dstall=0;fstall=0;end
    end
    always @(*) begin//B
        if(ctr[13]|(zero&ctr[10])) begin dflush=1; end
        else begin dflush=0;end
    end
    always @(*) begin//B
        if(ctr[13]|(zero&ctr[10])|(rd==ir[19:15]|rd==ir[24:20])&ctr[9]) begin eflush=1; end
        else begin eflush=0;end
    end
endmodule
