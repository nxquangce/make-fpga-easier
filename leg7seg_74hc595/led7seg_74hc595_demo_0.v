`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/30/2022 10:12:20 AM
// Design Name: 
// Module Name: led7seg_74hc595_demo_0
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Display "76543210" on 8 7-seg LEDs 74HC595 module
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module led7seg_74hc595_demo_0(
    clk,
    rst,
    sclk,
    rclk,
    dio
    );

parameter NUM_0 = 8'hC0, NUM_1 = 8'hF9, NUM_2 = 8'hA4, NUM_3 = 8'hB0, NUM_4 = 8'h99,
          NUM_5 = 8'h92, NUM_6 = 8'h82, NUM_7 = 8'hF8, NUM_8 = 8'h80, NUM_9 = 8'h90,
          NUM_A = 8'h8C, NUM_b = 8'hBF, NUM_C = 8'hC6, NUM_d = 8'hA1, NUM_E = 8'h86,
          NUM_F = 8'hFF, NUM_LINE = 8'hbf;

input clk;
input rst;
output sclk;
output rclk;
output dio;

reg [15:0] data;
reg [ 2:0] cnt;
wire       next_vld;
wire       vld;

always @(posedge clk) begin
    if (rst) cnt <= 0;
    else if (vld) begin
        cnt <= cnt + 1'b1; 
    end
end

wire ready;
assign vld = ready;

always @(posedge clk) begin
    if (rst) data <= {NUM_0, 8'h01};
    else begin
        case (cnt)
            'd0: data <= {NUM_0, 8'h01};
            'd1: data <= {NUM_1, 8'h02};
            'd2: data <= {NUM_2, 8'h04};
            'd3: data <= {NUM_3, 8'h08};
            'd4: data <= {NUM_4, 8'h10};
            'd5: data <= {NUM_5, 8'h20};
            'd6: data <= {NUM_6, 8'h40};
            'd7: data <= {NUM_7, 8'h80};
            default: data <= 16'h0000;
        endcase
    end
end

mfe_led7seg_74hc595_controller led7seg_ctrl(
    .clk    (clk),
    .rst    (rst),
    .dat    (data),
    .vld    (vld),
    .rdy    (ready),

    .sclk   (sclk),
    .rclk   (rclk),
    .dio    (dio)
    );

endmodule
