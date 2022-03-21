`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: .
// Engineer: .
// 
// Create Date: 03/20/2022 09:05:49 PM
// Design Name: LCD1602 controller demo 0
// Module Name: mfe_lcd1602_demo_0
// Project Name: Make FPGA easier
// Target Devices: Arty-Z7/any
// Tool Versions: 2018.2/any
// Description: Display string "Welcome to the Digilent Arty-Z7" on LCD1602
// 
// Dependencies: mfe_lcd1602_controller.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mfe_lcd1602_demo_0(
    clk,
    rst,
    lcd_rs,
    lcd_rw,
    lcd_en,
    lcd_data
    );

input           clk;
input           rst;
output          lcd_rs;
output          lcd_rw;
output          lcd_en;
output [7 : 0]  lcd_data;

reg  [7 : 0] cnt;
reg          vld;
reg  [9 : 0] lut;
wire         ready;
wire         cmd;
wire         lwt;
wire [7 : 0] dat;

always @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
    end
    else if (cnt < 8'hff) begin
        if (ready & vld) cnt <= cnt + 1'b1;
    end
end

always @(posedge clk) begin
    if (rst) begin
        lut <= 10'b0;
    end
    else begin
        case (cnt)
            // Initial
            8'd0: lut <= 10'h138;
            8'd1: lut <= 10'h10C;
            8'd2: lut <= 10'h301;
            8'd3: lut <= 10'h106;
            8'd4: lut <= 10'h180;
            //  Line 1
            8'd5: lut <= 10'h020;   //  Welcome to the
            8'd6: lut <= 10'h057;
            8'd7: lut <= 10'h065;
            8'd8: lut <= 10'h06C;
            8'd9: lut <= 10'h063;
            8'd10: lut <= 10'h06F;
            8'd11: lut <= 10'h06D;
            8'd12: lut <= 10'h065;
            8'd13: lut <= 10'h020;
            8'd14: lut <= 10'h074;
            8'd15: lut <= 10'h06F;
            8'd16: lut <= 10'h020;
            8'd17: lut <= 10'h074;
            8'd18: lut <= 10'h068;
            8'd19: lut <= 10'h065;
            8'd20: lut <= 10'h020;
            //  Change Line
            8'd21: lut <= 10'h1C0;
            //  Line 2
            8'd22: lut <= 10'h044;   // Digilent Arty-Z7
            8'd23: lut <= 10'h069;   // i
            8'd24: lut <= 10'h067;   // g
            8'd25: lut <= 10'h069;   // i
            8'd26: lut <= 10'h06C;   // l
            8'd27: lut <= 10'h065;   // e
            8'd28: lut <= 10'h06E;   // n
            8'd29: lut <= 10'h074;   // t
            8'd30: lut <= 10'h020;   // 
            8'd31: lut <= 10'h041;   // A
            8'd32: lut <= 10'h072;   // r
            8'd33: lut <= 10'h074;   // t
            8'd34: lut <= 10'h079;   // y
            8'd35: lut <= 10'h0B0;   // -
            8'd36: lut <= 10'h05A;   // Z
            8'd37: lut <= 10'h037;   // 7
            default: lut <= 10'h120;
        endcase
    end
end

always @(posedge clk) begin
    if (rst) begin
        vld <= 1'b0;
    end
    else begin
        vld <= ready & (cnt < 8'd38);
    end
end

assign lwt = lut[9];
assign cmd = lut[8];
assign dat = lut[7:0];

mfe_lcd1602_controller #(
    .T_LW_MAX   (18'd200000)
    ) 
lcd_ctrl (
    .clk        (clk),
    .rst        (rst),
    .cmd        (cmd),
    .dat        (dat),
    .vld        (vld),
    .lwt        (lwt),
    .ready      (ready),

    .lcd_rs     (lcd_rs),
    .lcd_rw     (lcd_rw),
    .lcd_en     (lcd_en),
    .lcd_data   (lcd_data)
);

endmodule
