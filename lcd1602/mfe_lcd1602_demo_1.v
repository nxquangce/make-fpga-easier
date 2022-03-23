`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: .
// Engineer: .
// 
// Create Date: 03/21/2022 01:11:57 PM
// Design Name: LCD1602 controller demo 1
// Module Name: mfe_lcd1602_demo_1
// Project Name: Make FPGA easier
// Target Devices: Arty-Z7/any
// Tool Versions: 2018.2/any
// Description: Test LCD1602 Controller Wrapper
// 
// Dependencies: 
//  - mfe_lcd1602_controller.v
//  - mfe_lcd1602_controller_wrapper.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mfe_lcd1602_demo_1(
    clk,
    rst,
    clear,
    home,
    disp,
    cenb,
    shift,
    lcd_rs,
    lcd_rw,
    lcd_en,
    lcd_data
    );

localparam A = 8'h41, B = 8'h42, C = 8'h43, D = 8'h44, E = 8'h45, F = 8'h46,
           G = 8'h47, H = 8'h48, I = 8'h49, J = 8'h4a, K = 8'h4b, L = 8'h4c,
           M = 8'h4d, N = 8'h4e, O = 8'h4f, P = 8'h50, Q = 8'h51, R = 8'h52,
           S = 8'h53, T = 8'h54, U = 8'h55, V = 8'h56, W = 8'h57, X = 8'h58,
           Y = 8'h59, Z = 8'h5a, SPACE = 8'h20;
localparam a = 8'h61, b = 8'h62, c = 8'h63, d = 8'h64, e = 8'h65, f = 8'h66,
           g = 8'h67, h = 8'h68, i = 8'h69, j = 8'h6a, k = 8'h6b, l = 8'h6c,
           m = 8'h6d, n = 8'h6e, o = 8'h6f, p = 8'h70, q = 8'h71, r = 8'h72,
           s = 8'h73, t = 8'h74, u = 8'h75, v = 8'h76, w = 8'h77, x = 8'h78,
           y = 8'h79, z = 8'h7a;
localparam NUM0 = 8'h30;

input           clk;
input           rst;
input           clear;
input           home;
input           disp;
input           cenb;
input  [1 : 0]  shift;
output          lcd_rs;
output          lcd_rw;
output          lcd_en;
output [7 : 0]  lcd_data;

wire cmd;
wire ready;
reg cenb_pp;
reg [7 : 0] dat;
reg         vld;

always @(posedge clk) begin
    cenb_pp <= cenb;
end

assign cmd = (dat == 8'hC0) & vld;

//LCD1602 Demo 1
localparam CHAR_CNT_MAX = 5'd31;
reg [4 : 0] char_cnt;

always @(posedge clk) begin
    if (rst) begin
        char_cnt <= 5'b0;
    end
    else if (char_cnt < CHAR_CNT_MAX) begin
        char_cnt <= (ready) ? char_cnt + 1'b1 : char_cnt;
    end
end

always @(*) begin
    case (char_cnt)
        5'd0: dat = M;
        5'd1: dat = a;
        5'd2: dat = k;
        5'd3: dat = e;
        5'd4: dat = SPACE;
        5'd5: dat = F;
        5'd6: dat = P;
        5'd7: dat = G;
        5'd8: dat = A;
        5'd9: dat = SPACE;
        5'd10: dat = e;
        5'd11: dat = a;
        5'd12: dat = s;
        5'd13: dat = i;
        5'd14: dat = e;
        5'd15: dat = r;
        5'd16: dat = 8'hC0; // New line
        5'd17: dat = L;
        5'd18: dat = C;
        5'd19: dat = D;
        5'd20: dat = NUM0 + 1;
        5'd21: dat = NUM0 + 6;
        5'd22: dat = NUM0 + 0;
        5'd23: dat = NUM0 + 2;
        5'd24: dat = SPACE;
        5'd25: dat = D;
        5'd26: dat = e;
        5'd27: dat = m;
        5'd28: dat = o;
        5'd29: dat = SPACE;
        5'd30: dat = NUM0 + 1;
        5'd31: dat = SPACE;
        default: begin
            dat = SPACE;
        end
    endcase

    vld = ready & char_cnt < CHAR_CNT_MAX;
end


mfe_lcd1602_controller_wrapper lcd_ctrl (
    .clk            (clk),
    .rst            (rst),
    .clear          (clear),
    .home           (home),
    .cenb           (cenb_pp),
    .disp           (disp),
    .dat            (dat),
    .cmd            (cmd),
    .vld            (vld),
    .shift          (shift),
    .ready          (ready),

    .lcd_rs         (lcd_rs),
    .lcd_rw         (lcd_rw),
    .lcd_en         (lcd_en),
    .lcd_data       (lcd_data)
    );

endmodule
