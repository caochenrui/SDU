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
    output reg        type_tx,
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
    localparam BP3P    = 7;
    localparam BP3W    = 8;
    localparam BP4P    = 9;
    localparam BP4W    = 10;
    localparam BP5P    = 11;
    localparam BP5W    = 12;
    localparam BP6P    = 13;
    localparam BP6W    = 14;
    localparam BP7P    = 15;
    localparam BP7W    = 16;
    localparam BP8P    = 17;
    localparam BP8W    = 18;

    reg        clk_cpu_next;
    reg [4:0]  state, state_next;
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
                                state_next = BP7W;
                            else
                                state_next = BP1W;
                        end
                    endcase
                end
            end

            STEP: state_next = IDLE;

            BP1W: state_next = busy_tx ? BP1P : BP1W;

            BP1P: begin
                if (busy_tx)
                    state_next = BP1P;
                else
                    state_next = BP2W;
            end

            BP2W: state_next = busy_tx ? BP2P : BP2W;

            BP2P: begin
                if (busy_tx)
                    state_next = BP2P;
                else
                    state_next = BP3W;
            end

            BP3W: state_next = busy_tx ? BP3P : BP3W;

            BP3P: begin
                if (busy_tx)
                    state_next = BP3P;
                else if (bp_count == 2)
                    state_next = BP4W;
                else
                    state_next = BP7W;
            end

            BP4W: state_next = busy_tx ? BP4P : BP4W;

            BP4P: begin
                if (busy_tx)
                    state_next = BP4P;
                else
                    state_next = BP5W;
            end

            BP5W: state_next = busy_tx ? BP5P : BP5W;

            BP5P: begin
                if (busy_tx)
                    state_next = BP5P;
                else
                    state_next = BP6W;
            end

            BP6W: state_next = busy_tx ? BP6P : BP6W;

            BP6P: begin
                if (busy_tx)
                    state_next = BP6P;
                else
                    state_next = BP7W;
            end

            BP7W: state_next = busy_tx ? BP7P : BP7W;

            BP7P: begin
                if (busy_tx)
                    state_next = BP7P;
                else
                    state_next = BP8W;
            end

            BP8W: state_next = busy_tx ? BP8P : BP8W;

            BP8P: begin
                if (busy_tx)
                    state_next = BP8P;
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

    // assign type_tx = 1;

    always @(*) begin
        dout_tx = 32'b0;
        req_tx  = 1'b0;
        type_tx = 1;

        case (state_next)
            BP1W: begin
                dout_tx = 66;
                req_tx  = 1'b1;
                type_tx = 0;
            end

            BP1P: begin
                dout_tx = 66;
                req_tx  = 1'b0;
                type_tx = 0;
            end

            BP2W: begin
                dout_tx = 32;
                req_tx  = 1'b1;
                type_tx = 0;
            end

            BP2P: begin
                dout_tx = 32;
                req_tx  = 1'b0;
                type_tx = 0;
            end

            BP3W: begin
                dout_tx = bp1_next;
                req_tx  = 1'b1;
                type_tx = 1;
            end

            BP3P: begin
                dout_tx = bp1_next;
                req_tx  = 1'b0;
                type_tx = 1;
            end

            BP4W: begin
                dout_tx = 66;
                req_tx  = 1'b1;
                type_tx = 0;
            end

            BP4P: begin
                dout_tx = 66;
                req_tx  = 1'b0;
                type_tx = 0;
            end

            BP5W: begin
                dout_tx = 32;
                req_tx  = 1'b1;
                type_tx = 0;
            end

            BP5P: begin
                dout_tx = 32;
                req_tx  = 1'b0;
                type_tx = 0;
            end

            BP6W: begin
                dout_tx = bp2_next;
                req_tx  = 1'b1;
                type_tx = 1;
            end

            BP6P: begin
                dout_tx = bp2_next;
                req_tx  = 1'b0;
                type_tx = 1;
            end

            BP7W: begin
                dout_tx = 8'h0D;
                req_tx  = 1'b1;
                type_tx = 0;
            end

            BP7P: begin
                dout_tx = 8'h0D;
                req_tx  = 1'b0;
                type_tx = 0;
            end

            BP8W: begin
                dout_tx = 8'h0A;
                req_tx  = 1'b1;
                type_tx = 0;
            end

            BP8P: begin
                dout_tx = 8'h0A;
                req_tx  = 1'b0;
                type_tx = 0;
            end
        endcase
    end
endmodule
