`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/30/2022 12:02:39 PM
// Design Name: 
// Module Name: mfe_led7seg_74hc595_demo_1
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


module mfe_led7seg_74hc595_demo_1(
    clk,
    rst,
    btn,
    sclk,
    rclk,
    dio
    );

parameter   DIG_NUM       = 8;
parameter   SEG_NUM       = 8;
localparam  CHA_WIDTH     = DIG_NUM + SEG_NUM;
localparam  DAT_WIDTH     = SEG_NUM * DIG_NUM;
parameter   DIV_WIDTH     = 8;

parameter NUM_0 = 8'hC0, NUM_1 = 8'hF9, NUM_2 = 8'hA4, NUM_3 = 8'hB0, NUM_4 = 8'h99,
          NUM_5 = 8'h92, NUM_6 = 8'h82, NUM_7 = 8'hF8, NUM_8 = 8'h80, NUM_9 = 8'h90,
          NUM_A = 8'h8C, NUM_b = 8'hBF, NUM_C = 8'hC6, NUM_d = 8'hA1, NUM_E = 8'h86,
          NUM_F = 8'hFF, NUM_LINE = 8'hbf;

input clk;
input rst;
input btn;
output sclk;
output rclk;
output dio;

reg [DAT_WIDTH - 1 : 0] data;
reg                     rst_vld;
reg                     btn_vld_p;
reg                     btn_vld_n;
reg               [2:0] ff_rst;
reg               [2:0] ff_btn;
wire                    vld;

always @(posedge clk) begin
    if (rst) begin
        data <= {NUM_7, NUM_6, NUM_5, NUM_4, NUM_3, NUM_2, NUM_1, NUM_0};
    end
    else if (btn_vld_p) begin
        data <= {data[DAT_WIDTH - SEG_NUM - 1 : 0], data[DAT_WIDTH - 1 : DAT_WIDTH - SEG_NUM]};
    end
end

always @(posedge clk) begin
    ff_rst[0]   <= rst;
    ff_rst[2:1] <= ff_rst[1:0];
    ff_btn[0]   <= btn;
    ff_btn[2:1] <= ff_btn[1:0];
    rst_vld     <= ff_rst[2] & ~ff_rst[1];
    btn_vld_n   <= ff_btn[2] & ~ff_btn[1];
    btn_vld_p   <= ~ff_btn[2] & ff_btn[1];
end

assign vld = rst_vld | btn_vld_n;

mfe_led7seg_74hc595_wrapper
    #(
    .DIG_NUM    (DIG_NUM),
    .SEG_NUM    (SEG_NUM),
    .DIV_WIDTH  (DIV_WIDTH)
    )
led7seg_ctrl_wrapper(
    .clk        (clk),
    .rst        (rst),
    .dat        (data),
    .vld        (vld),

    .sclk       (sclk),
    .rclk       (rclk),
    .dio        (dio)
    );

endmodule
