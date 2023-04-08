module Serial_Debug_Unit#(
    parameter WIDTH=32
)(
    input clk,rstn,
    input rxd,
    output txd,
    output busy,
    output [2:0]scan_state,
    // output reg [9:0]check1,
    output [3:0]check,
    output clk_cpu,
    input [31:0] pc_chk,
    input [31:0] npc,pc,ir,pcd,
    input [31:0] ire,imm,a,b,pce,ctr,
    input [31:0] irm,mdw,y,ctrm,
    input [31:0] irw,yw,mdr,ctrw,
    output reg [WIDTH-1:0] addr,
    input [WIDTH-1:0] dout_rf,dout_dm,dout_im,
    output [WIDTH-1:0] din,
    output we_dm,we_im,
    output clk_ld,
    output reg ld
);

    reg clk_rx;//153600Hz
    reg clk_tx;//9600Hz 发�?�用
    reg [2:0]cnt2; //16倍于clk1
    reg [8:0]cnt1; //651倍于clk
    always @(posedge clk,negedge rstn) begin
        if(!rstn)begin
            clk_rx<=0;
            cnt1<=0;
        end
        else begin
            if(cnt1==9'd325)begin
                cnt1<=0;
                clk_rx=~clk_rx;
            end
            else cnt1<=cnt1+1;
        end
    end
    always @(posedge clk_rx,negedge rstn) begin
        if(!rstn)begin
            clk_tx<=0;
            cnt2<=0;
        end
        else begin
            cnt2<=cnt2+1;
            if(cnt2==4'd7)clk_tx=~clk_tx;
        end
    end
    assign clk_ld=clk_rx;

    localparam LOADINST=0,WAITINST=1,DEINST=2,WAITPIN_LID=3,WAITPIN_PRDI=4,WAITPIN_TBGH=5,
    IN_PRDI=6,WAIT_PRDI=7,IN_TBGH=8,WAIT_TBGH=9,IN_LID=10,WAIT_LID=11,GETINST=12,CLEAN_LID=13;
    reg [5:0] ns,cs;
    assign check=cs[3:0];
    wire [WIDTH-1:0] din_rx; wire flag_rx; reg type_rx; reg req_rx;wire busy_rx;reg scan_stop;reg [WIDTH-1:0] wd,nwd;
    assign busy=busy_rx;
    
    reg [WIDTH-1:0] dout_tx;reg type_tx;reg req_tx; wire busy_tx;
    
    wire [WIDTH-1:0] addr_prdi; reg we_prdi,nwe_prdi;wire busy_prdi;reg exe_prdi;reg [1:0] sl_prdi,nsl_prdi;
    wire [WIDTH-1:0] dout_prdi;wire type_prdi; wire req_prdi;
    
    wire busy_tbgh; reg exe_tbgh;reg [1:0] sl_tbgh,nsl_tbgh;reg we_tbgh,nwe_tbgh;reg halt,nhalt;wire [WIDTH-1:0] dout_tbgh;
    wire type_tbgh; wire req_tbgh;
    
    wire busy_lid;reg exe_lid; reg sl_lid,nsl_lid;wire [WIDTH-1:0] addr_lid;wire type_rlid;wire req_rlid;
    wire [WIDTH-1:0] dout_lid;wire type_tlid;wire req_tlid;

    I_O(.scan_state(scan_state),.clk_rx(clk_rx),.clk_tx(clk_tx),.rstn(rstn),.rxd(rxd),.txd(txd),.din_rx(din_rx),.flag_rx(flag_rx),.type_rx(type_rx),.req_rx(req_rx),.bsy_rx(busy_rx),
    .scan_stop(scan_stop),
    .dout_tx(dout_tx),.type_tx(type_tx),.req_tx(req_tx),.bsy_tx(busy_tx));
    
    PRDI(.clk(clk_rx),.rstn(rstn),.exe(exe_prdi),
    .npc(npc),.pc(pc),.ir(ir),.pcd(pcd),
    .ire(ire),.imm(imm),.a(a),.b(b),.pce(pce),.ctr(ctr),
    .irm(irm),.mdw(mdw),.y(y),.ctrm(ctrm),
    .irw(irw),.yw(yw),.mdr(mdr),.ctrw(ctrw),
    .addr_out(addr_prdi),
    .mode(sl_prdi),
    .dout_rf(dout_rf),.dout_dm(dout_dm)
    ,.dout_im(dout_im),
    .enable(we_prdi),.addr_in(wd),
    .PRDI_busy(busy_prdi),.print_busy(busy_tx),.dout_tx(dout_prdi),.type_tx(type_prdi),.req_tx(req_prdi)
    );
    
    FSMLOAD(.busy(busy_lid),.exe(exe_lid),.type(sl_lid),.addr(addr_lid),.clk(clk_rx),.rstn(rstn),.din(din),.we_dm(we_dm),
    .din_rx(din_rx),.flag_rx(flag_rx),.type_rx(type_rlid),.req_rx(req_rlid),.bsy_rx(busy_rx),.we_im(we_im),
    .dout_tx(dout_lid),.type_tx(type_tlid),.req_tx(req_tlid),.bsy_tx(busy_tx));
    
    cpu_control_unit(.pc_chk(pc_chk),.clk(clk_rx),.rstn(rstn),.busy(busy_tbgh),.exe(exe_tbgh),.sel(sl_tbgh),.we(we_tbgh),.bp_in(wd),.halt(halt),
    .clk_cpu(clk_cpu),.dout_tx(dout_tbgh),.type_tx(type_tbgh),.req_tx(req_tbgh),.busy_tx(busy_tx)
    );
    
   always@(posedge(clk_rx),negedge(rstn))
    begin
    if(!rstn)
        begin
        cs<=LOADINST;
        sl_prdi<=0;
        sl_tbgh<=0;
        sl_lid<=0;
        wd<=0;
        we_tbgh<=0;
        we_prdi<=0;
        halt<=0;
        end
    else
        begin
        sl_prdi<=nsl_prdi;
        sl_tbgh<=nsl_tbgh;
        sl_lid<=nsl_lid;
        cs<=ns;
        wd<=nwd;
        we_tbgh<=nwe_tbgh;
        we_prdi<=nwe_prdi;
        halt<=nhalt;
        end
    end
    // always @(posedge clk_rx,negedge rstn) begin
    //     if(!rstn)begin
    //         check1<=0;
    //     end
    //     else begin
    //         // check1[2:0]<=sload[3:1];
    //         if(ns==WAITPIN_LID)check1[0]<=1;
    //         if(ns==IN_LID)check1[1]<=1;
    //         if(ns==WAIT_LID)check1[2]<=1;
    //         // if(ns==0)check1[3]<=1;
    //         // if(ns==1)check1[4]<=1;
    //         // if(ns==2)check1[5]<=1;
    //         if(req_rlid)check1[3]<=1;
    //         check1[4]<=flag_rx;
    //         if(addr==2)check1[5]<=1;
    //         // if(ns==12)check1[9]<=1;
    //     end
    // end

    always@(*)
    begin
    nsl_prdi=sl_prdi;
    nsl_tbgh=sl_tbgh;
    nsl_lid=sl_lid;
    ns=LOADINST;
    type_rx=0;req_rx=0;scan_stop=0;
    dout_tx=0;type_tx=0;req_tx=0;
    exe_prdi=0;
    exe_tbgh=0;
    exe_lid=0;
    ld = 0;
    nwd=wd;
    nwe_tbgh=we_tbgh;
    nwe_prdi=we_prdi;
    nhalt=halt;
    addr=0;
    case(cs)
        LOADINST:
            begin
            scan_stop=1;
            if(busy_rx)
                ns=LOADINST;
            else
                ns=GETINST;
            end
        GETINST:
            begin
            if(busy_rx)
                ns=WAITINST;
            else
                ns=GETINST;
            req_rx=1;
            type_rx=0;
            end
        WAITINST:
            begin
            type_rx=0;
            nhalt=0;
            if(busy_rx)
                ns=WAITINST;
            else
                begin
                ns=DEINST;
                nwd=din_rx;
                end
            end
        DEINST:
            begin
            req_rx=1;
            if(wd[7:0]==8'h4C)//L
                begin
                if(busy_rx)
                    ns=WAITPIN_LID;
                else
                    ns=DEINST;
                type_rx=0;
                end
            else
                begin
                type_rx=1;
                if(!busy_rx)
                    ns=DEINST;
                else
                    begin
                    case(wd[7:0])
                        8'h50://P
                            begin
                            ns=IN_PRDI;
                            nsl_prdi=0;
                            end
                        8'h52://R
                            begin
                            ns=IN_PRDI;
                            nsl_prdi=1;
                            end
                        8'h44://D
                            begin
                            ns=WAITPIN_PRDI;
                            nsl_prdi=2;
                            end
                        8'h49://I
                            begin
                            ns=WAITPIN_PRDI;
                            nsl_prdi=3;
                            end
                        8'h54://T
                            begin
                            ns=WAITPIN_TBGH;
                            nsl_tbgh=0;
                            end
                        8'h42://B
                            begin
                            ns=WAITPIN_TBGH;
                            nsl_tbgh=1;
                            end
                        8'h47://G
                            begin
                            ns=WAITPIN_TBGH;
                            nsl_tbgh=2;
                            end
                        default:
                            ns=LOADINST;
                    endcase
                    end
                end     
            end
        WAITPIN_PRDI:
            begin
            type_rx=1;
            if(busy_rx)
                ns=WAITPIN_PRDI;  
            else
                begin
                ns=IN_PRDI;
                nwe_prdi=~flag_rx;
                nwd=din_rx;
                end
            end
        IN_PRDI:
            begin
            if(busy_prdi)
                ns=WAIT_PRDI;
            else
                ns=IN_PRDI;
            exe_prdi=1;
            addr=addr_prdi;
            dout_tx=dout_prdi;
            type_tx=type_prdi;
            req_tx=req_prdi;
            end
        WAIT_PRDI:
            begin
            if(busy_prdi)
                ns=WAIT_PRDI;
            else
                ns=LOADINST;
            addr=addr_prdi;
            dout_tx=dout_prdi;
            type_tx=type_prdi;
            req_tx=req_prdi;
            end
        WAITPIN_TBGH:
            begin
            type_rx=1;
            if(busy_rx)
                ns=WAITPIN_TBGH;  
            else
                begin
                ns=IN_TBGH;
                nwd=din_rx;
                if(sl_tbgh==1)
                    nwe_tbgh=~flag_rx;
                end
            end
       IN_TBGH:
            begin
            if(busy_tbgh)
                ns=WAIT_TBGH;
            else
                ns=IN_TBGH;
            exe_tbgh=1;
            dout_tx=dout_tbgh;
            type_tx=type_tbgh;
            req_tx=req_tbgh;
            end
        WAIT_TBGH:
            begin
            if(busy_tbgh)
                begin
                ns=WAIT_TBGH;
                dout_tx=dout_tbgh;
                type_tx=type_tbgh;
                req_tx=req_tbgh;
                if(sl_tbgh==2)
                    begin
                    if(din_rx[7:0]==8'h48 && busy_rx==0)//H
                        begin
                        if(busy_tbgh)
                            ns=WAIT_TBGH;
                        else
                            ns=LOADINST;
                        nhalt=1;
                        req_rx=1;
                        type_rx=1;
                        end
                    else
                        begin
                        req_rx=1;
                        type_rx=0;
                        end
                    end
                end
            else
                begin
                if(sl_tbgh==0)
                    begin
                    ns=IN_PRDI;
                    nsl_prdi=0;
                    end
                else
                    ns=LOADINST;
                end
            end
         WAITPIN_LID:
            begin
            ld = 1;
            type_rx=0;
            if(busy_rx)
                ns=WAITPIN_LID;  
            else
                begin
                ns= CLEAN_LID;
                if(din_rx[7:0]==8'h49)//I
                    nsl_lid=0;
                else if(din_rx[7:0]==8'h44)//D
                    nsl_lid=1;
                else
                    ns=LOADINST;
                end
            end
        CLEAN_LID:
            begin
            ld = 1;
            if(busy_rx)
                begin
                ns=IN_LID;
                end
            else
                begin
                req_rx=1;
                type_rx=1;
                ns=CLEAN_LID;
                end    
            end
        IN_LID:
            begin
            ld = 1;
            addr=addr_lid;            
            dout_tx=dout_lid;
            type_tx=type_tlid;
            req_tx=req_tlid;
            type_rx=type_rlid;
            req_rx=req_rlid;
            if(busy_rx)
                begin
                ns=IN_LID;
                end
            else
                begin
                if(busy_lid)
                    ns=WAIT_LID;
                else
                    ns=IN_LID;
                exe_lid=1;
                end
            end
        WAIT_LID:
            begin
            ld = 1;
            if(busy_lid)
                ns=WAIT_LID;
            else
                ns=LOADINST;
            addr=addr_lid;            
            dout_tx=dout_lid;
            type_tx=type_tlid;
            req_tx=req_tlid;
            type_rx=type_rlid;
            req_rx=req_rlid;
            end 
    endcase
    end

endmodule