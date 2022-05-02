`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Computer Engineering Lab - CSE - HCMUT
// Engineer: Nguyen Xuan Quang
// 
// Create Date: 03/21/2022 09:53:40 AM
// Design Name: LCD1602 Controller Wrapper
// Module Name: mfe_lcd1602_controller_wrapper
// Project Name: Make FPGA easier
// Target Devices: Arty-Z7/any
// Tool Versions: 2018.2/any
// Description: LCD1602 controller with implemented features
// 
// Dependencies: mfe_lcd1602_controller.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mfe_lcd1602_controller_wrapper(
    clk,
    rst,
    clear,
    home,
    cenb,
    disp,
    dat,
    cmd,
    vld,
    shift,
    ready,

    lcd_rs,
    lcd_rw,
    lcd_en,
    lcd_data
    );

////////////////////////////////////////////////////////////////////////////////
// Parameters

// Timer values are recommended for Fclk ~ 100MHz
parameter T_AS_MAX          = 6;         // address setup time
parameter T_PW_MAX          = 24;        // pulse width time
parameter T_LW_MAX          = 200000;    // description time long
parameter T_SW_MAX          = 5000;      // description time short
parameter T_WIDTH           = 18;        // Bitwidth of timer cnt
parameter SHORT_WAIT_ENABLE = 0;         // Enable short wait time, if = 0: wait time is T_LW_MAX

parameter CURSOR_ON         = 0;
parameter SHIFT_CNT_MAX     = 25'd31249999;
parameter SHIFT_CNT_WIDTH   = 25;

parameter FSM_WIDTH         = 3;
localparam S_IDLE           = 'd0;      // Idle
localparam S_INIT           = 'd1;      // Init
localparam S_LCMD           = 'd2;      // Long command
localparam S_SCMD           = 'd3;      // Short command
localparam S_SHIF           = 'd4;      // Shifting mode
localparam S_DATA           = 'd5;      // Send data

////////////////////////////////////////////////////////////////////////////////
// Ports declaration

input           clk;
input           rst;
input           clear;
input           home;
input           cenb;
input           disp;
input  [7 : 0]  dat;
input           cmd;
input           vld;
input  [1 : 0]  shift;
output          ready;

output          lcd_rs;
output          lcd_rw;
output          lcd_en;
output [7 : 0]  lcd_data;

////////////////////////////////////////////////////////////////////////////////

reg [FSM_WIDTH - 1 : 0] cur_state;
reg [FSM_WIDTH - 1 : 0] nxt_state;
reg [            4 : 0] func_reg;
reg [            7 : 0] data_reg;

reg         lcdctrl_cmd;
reg [7 : 0] lcdctrl_dat;
reg         lcdctrl_vld;
reg         lcdctrl_lwt;
reg         lcdctrl_ready_cache;
wire        lcdctrl_ready;
wire        lcdctrl_accept;
wire        lcdctrl_done;

reg         init_reg;
reg [2 : 0] init_cnt;
wire        init_cnt_max_vld;
wire        lcmd_cnt_max_vld;

reg [SHIFT_CNT_WIDTH - 1 : 0] shift_cnt;
wire                          shift_vld;

wire                          disp_vld;

assign lcdctrl_accept = lcdctrl_ready & lcdctrl_vld;
assign lcdctrl_done   = ~lcdctrl_ready_cache & lcdctrl_ready;

always @(posedge clk) begin
    func_reg <= {cmd, disp, cenb, home, clear};
    data_reg <= dat;
    lcdctrl_ready_cache <= lcdctrl_ready;
end

assign disp_vld = disp ^ func_reg[3];

// FSM
always @(posedge clk) begin
    if (rst) begin
        cur_state <= S_INIT;
    end
    else begin
        cur_state <= nxt_state;
    end
end

always @(*) begin
    case (cur_state)
        S_IDLE: begin
            lcdctrl_cmd = 1'b0;
            lcdctrl_dat = 8'b0;
            lcdctrl_vld = 1'b0;
            lcdctrl_lwt = 1'b0;
            if (!init_reg) begin
                nxt_state = lcdctrl_ready ? S_INIT : S_IDLE;
            end
            else begin
                nxt_state = (clear | home) ? S_LCMD :
                            (disp_vld | cenb | cmd) ? S_SCMD :
                            (|shift)       ? S_SHIF :
                            (vld)          ? S_DATA : S_IDLE;
            end
        end
        S_INIT: begin   // Setup LCD
            lcdctrl_cmd = 1'b1;
            lcdctrl_vld = 1'b1;
            lcdctrl_lwt = 1'b1;
            case (init_cnt)
                3'd0: lcdctrl_dat = 8'h38;  // data length 8 bit, 2 lines
                3'd1: lcdctrl_dat = 8'h0C;  // display on, no cursor
                3'd2: lcdctrl_dat = 8'h01;  // clear
                3'd3: lcdctrl_dat = 8'h06;  // cursor moves to right, DDRAM addr + 1, no shift
                3'd4: lcdctrl_dat = 8'h80;  // Set cursor to addr 0 at left top
                default: begin
                    lcdctrl_dat = 8'h80;
                    lcdctrl_vld = 1'b0;
                end
            endcase
            nxt_state = (init_cnt_max_vld & lcdctrl_done) ? S_IDLE : S_INIT;
        end
        S_LCMD: begin
            lcdctrl_cmd = 1'b1;
            lcdctrl_vld = 1'b1;
            lcdctrl_lwt = 1'b1;
            lcdctrl_dat = {6'b0, func_reg[1:0]};    // Return home is prior
            nxt_state = lcdctrl_done ? S_IDLE : S_LCMD;
        end
        S_SCMD: begin
            lcdctrl_cmd = 1'b1;
            lcdctrl_vld = lcdctrl_ready & ~lcdctrl_done;
            lcdctrl_lwt = 1'b0;
            if (func_reg[4]) begin
                lcdctrl_dat = {1'b1, data_reg[6:0]};    // Set DDRAM Address
            end
            else begin
                lcdctrl_dat = {5'b1, func_reg[3:2], 1'b0};
            end
            nxt_state = lcdctrl_done ? S_IDLE : S_SCMD;
        end
        S_DATA: begin
            lcdctrl_cmd = 1'b0;
            lcdctrl_vld = lcdctrl_ready & ~lcdctrl_done;
            lcdctrl_lwt = 1'b0;
            lcdctrl_dat = data_reg;
            nxt_state = lcdctrl_done ? S_IDLE : S_DATA;
        end
        S_SHIF: begin
            lcdctrl_cmd = 1'b1;
            lcdctrl_vld = shift_vld;
            lcdctrl_lwt = 1'b0;
            lcdctrl_dat = {4'b0001, shift, 2'b00};
            nxt_state = (~|shift & lcdctrl_done) ? S_IDLE : S_SHIF;
        end
        default: begin
            nxt_state = S_IDLE;
            lcdctrl_cmd = 1'b0;
            lcdctrl_dat = 8'b0;
            lcdctrl_vld = 1'b0;
            lcdctrl_lwt = 1'b0;
        end
    endcase
end

assign ready = (cur_state == S_IDLE) & init_reg;

// Init counter
localparam INIT_CNT_MAX = 3'd5;
// localparam LCMD_CNT_MAX = 3'd2;

always @(posedge clk) begin
    if (rst) begin
        init_reg <= 1'b0;
    end
    else if (init_cnt_max_vld) begin
        init_reg <= 1'b1;
    end
end

assign init_cnt_max_vld = init_cnt == INIT_CNT_MAX;
// assign lcmd_cnt_max_vld = init_cnt == LCMD_CNT_MAX;

always @(posedge clk) begin
    if (rst) begin
        init_cnt <= 3'b0;
    end
    else if (cur_state == S_INIT) begin
        init_cnt <= (lcdctrl_accept) ? init_cnt + 1'b1 : init_cnt;
    end
    else begin
        init_cnt <= 3'b0;
    end
end

// Shift counter
assign shift_vld = shift_cnt == 25'b0;

always @(posedge clk) begin
    if (rst)begin
        shift_cnt <= 25'b0;
    end
    else if (cur_state == S_SHIF) begin
        shift_cnt <= (shift_vld) ? SHIFT_CNT_MAX : shift_cnt - 1'b1;
    end
end

mfe_lcd1602_controller 
    #(
    .T_AS_MAX           (T_AS_MAX),
    .T_PW_MAX           (T_PW_MAX),
    .T_LW_MAX           (T_LW_MAX),
    .T_SW_MAX           (T_SW_MAX),
    .T_WIDTH            (T_WIDTH),
    .SHORT_WAIT_ENABLE  (SHORT_WAIT_ENABLE)
    )
lcd_ctrl_i (
    .clk                (clk),
    .rst                (rst),
    .cmd                (lcdctrl_cmd),
    .dat                (lcdctrl_dat),
    .vld                (lcdctrl_vld),
    .lwt                (lcdctrl_lwt),
    .ready              (lcdctrl_ready),

    .lcd_rs             (lcd_rs),
    .lcd_rw             (lcd_rw),
    .lcd_en             (lcd_en),
    .lcd_data           (lcd_data)
);

endmodule
