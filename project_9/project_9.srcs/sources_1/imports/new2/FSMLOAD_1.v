module FSMLOAD(
    input exe,
    output reg busy,
    input clk,
    input rstn,
    input type,
    input [32:1]din_rx,
    input flag_rx,
    output type_rx,
    output reg req_rx,
    input bsy_rx,
    output reg [32:1]dout_tx,
    output type_tx,
    output reg req_tx,
    input bsy_tx,
    output reg [32:1]din,//8?
    output reg [32:1]addr,
    output reg we_dm,
    output reg we_im
);
    assign type_rx=1;
    assign type_tx=0;
    reg [4:1]count;
    localparam  
    ZERO    = 4'b0000,
    ONE     = 4'b0001,
    TWO     = 4'b0010,
    THREE   = 4'b0011,
    FOUR    = 4'b0100,
    FIVE    = 4'b0101,
    SIX     = 4'b0110,
    SEVEN   = 4'b0111,
    EIGHT   = 4'b1000,
    NINE    = 4'b1001,
    TEN     = 4'b1010,
    ELEVEN  = 4'b1011,
    TWELVE  = 4'b1100,
    THIRTEEN= 4'b1101,
    FOURTEEN= 4'b1110,
    FIFTEEN = 4'B1111;

    reg [4:1]s;
    reg [4:1]ns;

    always  @(posedge clk, negedge rstn)
    begin
        if (!rstn)   s <= ZERO;
        else         s <= ns;
    end

    always  @(*) begin
        ns = s;
        case (s)
            ZERO: begin//waiting
                if(exe) ns = FOURTEEN;
                else ns=ZERO;
            end
            FOURTEEN:
                  if(bsy_rx) ns = ONE;
                  else ns = FOURTEEN;
            ONE: begin//waiting for scan to complete
                if(!bsy_rx) if(!flag_rx) ns = TWO; else ns=SIX;
                else ns = ONE;
            end
            TWO: begin//fetch [32:1]din_rx, send [32:25]din_rx
                ns = FOURTEEN;
            end
            SIX: begin//no more data,print finish
                if (!count&!bsy_tx&!req_tx)ns=SEVEN;
                else ns = SIX;
            end
            SEVEN: begin//set busy  to 0
                ns = ZERO;
            end

        endcase
    end

    always @(posedge clk or negedge rstn)
        if (!rstn) begin busy<=0;req_rx<=0;we_dm<=0;we_im<=0;addr<=-1;din<=0;count<=8;dout_tx<=0;req_tx<=0; end
        else begin
            case (ns)
                ZERO:   
                    begin 
                        busy<=0;req_rx<=0;we_dm<=0;we_im<=0;addr<=-1;din<=0;count<=8;dout_tx<=0;req_tx<=0; 
                    end
                FOURTEEN:
                    begin
                        we_im<=0;
                        we_dm<=0;
                        req_rx<=1;
                        busy<=1; 
                    end
                ONE:    
                    begin 
                        req_rx<=0;
                    end
                TWO:    
                    begin 
                        if(!type)we_im<=1;
                        else we_dm<=1;
                        addr<=addr+1;
                        din<=din_rx;
                    end
                // THREE:
                //     begin 
                //         addr<=addr+1;
                //         din<=din_rx[16:9];
                //     end
                // FOUR:
                //     begin 
                //         addr<=addr+1;
                //         din<=din_rx[24:17];
                //     end
                // FIVE:
                //     begin 
                //         addr<=addr+1;
                //         din<=din_rx[32:25];
                //     end
                SIX:
                    begin
                        if(!bsy_tx) 
                        begin
                            if (!req_tx)
                            begin
                                case (count)
                                    8:dout_tx<=8'h46;
                                    7:dout_tx<=8'h69;
                                    6:dout_tx<=8'h6E;
                                    5:dout_tx<=8'h69;
                                    4:dout_tx<=8'h73;
                                    3:dout_tx<=8'h68;
                                    2:dout_tx<=8'h0D;
                                    1:dout_tx<=8'h0A;
                                endcase
                                count<=count-1;
                                req_tx<=1;
                            end
                        end
                        else if(req_tx==1)req_tx<=0;
                    end
                SEVEN:
                    begin
                        busy<=0;
                    end
            endcase
    end
endmodule