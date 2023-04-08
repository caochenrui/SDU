`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2023/03/17 09:53:37
// Design Name:
// Module Name: cpu_control_unit
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


module cpu_control_unit(
    input clk, rstn,

    input             exe,
    input      [1:0]  sel,
    input             halt,
    output            busy,

    input             we,
    input      [31:0] bp_in,

    input      [31:0] pc_chk,
    output reg        clk_cpu,

    input             busy_tx,
    output reg [31:0] dout_tx,
    output            type_tx,
    output reg        req_tx
);
    localparam SEL_T   = 0;
    localparam SEL_B   = 1;
    localparam SEL_G   = 2;

    localparam IDLE    = 0;
    localparam STEP    = 1;
    localparam GO      = 2;
    localparam BP1W    = 3;
    localparam BP1P    = 4;
    localparam BP2W    = 5;
    localparam BP2P    = 6;

    reg        clk_cpu_next;
    reg [2:0]  state, state_next;
    reg [1:0]  bp_count, bp_count_next;
    reg [31:0] bp1, bp1_next;
    reg [31:0] bp2, bp2_next;

    always @(posedge clk) begin
        if (!rstn) begin
            state <= IDLE;
            clk_cpu <= 1'b0;

            bp1 <= 32'b0;
            bp2 <= 32'b0;
            bp_count <= 0;
        end
        else begin
            state <= state_next;
            clk_cpu <= clk_cpu_next;

            bp1 <= bp1_next;
            bp2 <= bp2_next;
            bp_count <= bp_count_next;
        end
    end


    always @(*) begin
        state_next = IDLE;

        bp1_next = bp1;
        bp2_next = bp2;
        bp_count_next = bp_count;

        case (state)
            IDLE: begin
                if (exe) begin
                    case (sel)
                        SEL_T: state_next = STEP;
                        SEL_G: state_next = GO;
                        SEL_B: begin
                            if (we) begin
                                if (bp_count == 0) begin
                                    bp1_next = bp_in;
                                    bp2_next = bp1;
                                    bp_count_next = 1;
                                end
                                else if (bp_count == 1) begin
                                    if (bp_in == bp1) begin
                                        bp_count_next = 0;
                                    end
                                    else begin
                                        bp1_next = bp_in;
                                        bp2_next = bp1;
                                        bp_count_next = 2;
                                    end
                                end
                                else if (bp_count == 2) begin
                                    if (bp_in == bp1) begin
                                        bp1_next = bp2;
                                        bp_count_next = 1;
                                    end
                                    else if (bp_in == bp2) begin
                                        bp_count_next = 1;
                                    end
                                    else begin
                                        bp1_next = bp_in;
                                        bp2_next = bp1;
                                    end
                                end
                            end

                            if (bp_count_next == 0)
                                state_next = IDLE;
                            else
                                state_next = BP1W;
                        end
                    endcase
                end
            end

            STEP: state_next = IDLE;

            BP1W: state_next = busy_tx ? BP1P : state_next;

            BP1P: begin
                if (busy_tx)
                    state_next = BP1P;
                else if (bp_count == 2)
                    state_next = BP2W;
                else
                    state_next = IDLE;
            end

            BP2W: state_next = busy_tx ? BP2P : state_next;

            BP2P: begin
                if (busy_tx)
                    state_next = BP2P;
                else
                    state_next = IDLE;
            end

            GO: begin
                if (halt)
                    state_next = IDLE;
                else if (bp_count == 0)
                    state_next = GO;
                else if (pc_chk == bp1)
                    state_next = IDLE;
                else if (bp_count == 2 && pc_chk == bp2)
                    state_next = IDLE;
                else
                    state_next = GO;
            end
        endcase
    end

    assign busy = state != IDLE;

    always @(*) begin
        case (state_next)
            STEP:    clk_cpu_next = 1;
            GO:      clk_cpu_next = ~clk_cpu;
            default: clk_cpu_next = 0;
        endcase
    end

    assign type_tx = 1;

    always @(*) begin
        dout_tx = 32'b0;
        req_tx  = 1'b0;
        
        case (state)
            BP1W: begin
                dout_tx = bp1;
                req_tx  = 1'b1;
            end

            BP1P: begin
                dout_tx = bp1;
                req_tx  = 1'b0;
            end

            BP2W: begin
                dout_tx = bp2;
                req_tx  = 1'b1;
            end

            BP2P: begin
                dout_tx = bp2;
                req_tx  = 1'b0;
            end
        endcase
    end
endmodule
