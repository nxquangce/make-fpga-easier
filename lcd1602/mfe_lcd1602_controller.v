`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 03/20/2022 06:55:04 PM
// Design Name: LCD 16x2 Controller
// Module Name: mfe_lcd1602_controller
// Project Name: Make FPGA easier
// Target Devices: Arty-Z7/any
// Tool Versions: 2018.2/any
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mfe_lcd1602_controller(
    clk,
    rst,
    cmd,
    dat,
    vld,
    lwt,
    ready,

    lcd_rs,
    lcd_rw,
    lcd_en,
    lcd_data
);

////////////////////////////////////////////////////////////////////////////////
// Paramters

// Timer value is recommended for Fclk ~ 100MHz
parameter T_AS_MAX          = 6;         // address setup time
parameter T_PW_MAX          = 24;        // pulse width time
parameter T_LW_MAX          = 180000;    // description time long
parameter T_SW_MAX          = 5000;      // description time short
parameter T_WIDTH           = 18;        // Bitwidth of timer cnt
parameter SHORT_WAIT_ENABLE = 1;         // Enable short wait time, if = 0: wait time is T_LW_MAX

localparam S_IDLE = 2'b00;
localparam S_INST = 2'b01;
localparam S_ENAB = 2'b10;
localparam S_WAIT = 2'b11;

////////////////////////////////////////////////////////////////////////////////
// Ports delcaration

input          clk;
input          rst;
input          cmd;
input  [7 : 0] dat;
input          vld;
input          lwt;
output         ready;
output         lcd_rs;
output         lcd_rw;
output         lcd_en;
output [7 : 0] lcd_data;

////////////////////////////////////////////////////////////////////////////////

reg [1 : 0] cur_state;
reg [1 : 0] nxt_state;
reg [7 : 0] dat_reg;
reg         cmd_reg;
reg         enb_reg;
reg         lwt_reg;

reg [T_WIDTH - 1 : 0] cnt;
wire                  cnt_enb;
wire                  cnt_max_vld;

// Cache input
always @(posedge clk) begin
    if (rst) begin
        dat_reg <= 8'b0;
        cmd_reg <= 1'b0;
        lwt_reg <= 1'b0;
    end
    if (vld) begin
        dat_reg <= dat;
        cmd_reg <= ~cmd;
        lwt_reg <= lwt;
    end
end

// Assign output
assign lcd_rs   = cmd_reg;
assign lcd_data = dat_reg;
assign lcd_rw   = 1'b0;
assign lcd_en   = enb_reg;
assign ready    = cur_state == S_IDLE;

// Controller FSM
always @(posedge clk) begin
    if (rst) begin
        cur_state <= S_IDLE;
    end
    else begin
        cur_state <= nxt_state;
    end
end

always @(*) begin
    if (rst) begin
        nxt_state = S_IDLE;
    end
    else begin
        case (cur_state)
            S_IDLE: begin
                nxt_state = vld ? S_INST : S_IDLE;
            end
            S_INST: begin
                nxt_state = cnt_max_vld ? S_ENAB : S_INST;
            end
            S_ENAB: begin
                nxt_state = cnt_max_vld ? S_WAIT : S_ENAB;
            end
            S_WAIT: begin
                nxt_state = cnt_max_vld ? S_IDLE : S_WAIT;
            end
            default: begin
                nxt_state = S_IDLE;
            end
        endcase

    end
end

// FSM output - lcd_en
always @(posedge clk) begin
    if (rst) begin
        enb_reg <= 1'b0;
    end
    else begin
        enb_reg <= cur_state == S_ENAB;
    end
end

// Counter for lcd timing characters
generate;
    if (SHORT_WAIT_ENABLE) begin
        assign cnt_max_vld = (cur_state == S_INST) ? cnt == T_AS_MAX :
                     (cur_state == S_ENAB) ? cnt == T_PW_MAX :
                     (cur_state == S_WAIT) ? lwt_reg ? cnt == T_LW_MAX : cnt == T_SW_MAX : 1'b0;
    end
    else begin
        assign cnt_max_vld = (cur_state == S_INST) ? cnt == T_AS_MAX :
                     (cur_state == S_ENAB) ? cnt == T_PW_MAX :
                     (cur_state == S_WAIT) ? cnt == T_LW_MAX : 1'b0;
    end
endgenerate

// assign cnt_max_vld = cnt == 0;
assign cnt_enb = cur_state != S_IDLE;

always @(posedge clk) begin
    if (rst) begin
        cnt <= {T_WIDTH{1'b0}};
    end
    else if (cnt_enb) begin
        cnt <= (cnt_max_vld) ? {T_WIDTH{1'b0}} : cnt + 1'b1;
    end
end

endmodule
