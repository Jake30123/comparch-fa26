`include "ws2812b.sv"
`include "controller.sv"
`include "cell_god.sv"

// led_matrix top level module

module top(
    input logic     clk, 
    input logic     SW, 
    input logic     BOOT, 
    output logic    _48b, 
    output logic    _45a
);

    logic [7:0] red_data;
    logic [7:0] green_data;
    logic [7:0] blue_data;

    logic [4:0] frame;
    logic [5:0] pixel;

    logic [23:0] shift_reg = 24'd0;
    logic load_sreg;
    logic transmit_pixel;
    logic shift;
    logic ws2812b_out;


    // Instance the WS2812B output driver
    ws2812b u1 (
        .clk            (clk), 
        .serial_in      (shift_reg[23]), 
        .transmit       (transmit_pixel), 
        .ws2812b_out    (ws2812b_out), 
        .shift          (shift)
    );

    // Instance the controller
    controller u2 (
        .clk            (clk), 
        .load_sreg      (load_sreg), 
        .transmit_pixel (transmit_pixel), 
        .pixel          (pixel), 
        .frame          (frame),
        .idle_done      (frame_start)
    );

    localparam logic [63:0] GREEN_START = { // Glider Top Left
            8'b01000000,
            8'b00100000,
            8'b11100000,
            8'b00000000,
            8'b00000000,
            8'b00000000,
            8'b00000000,
            8'b00000000
    };

    localparam logic [63:0] RED_START = { // Glider Top Right
            8'b00000010,
            8'b00000100,
            8'b00000111,
            8'b00000000,
            8'b00000000,
            8'b00000000,
            8'b00000000,
            8'b00000000
    };

    localparam logic [63:0] BLUE_START = { // Square
            8'b00000000,
            8'b00000000,
            8'b00000000,
            8'b00011000,
            8'b00011000,
            8'b00000000,
            8'b00000000,
            8'b00000000
    };

    // Instances the decider of the cells fate, one for each color
    deciderOfFate #(.BOARD_START(GREEN_START)) u3 (
        .clk            (clk),
        .frame_start    (frame_start),
        .pixel          (pixel),
        .pixel_value    (green_data)
    );
    deciderOfFate #(.BOARD_START(RED_START)) u4 (
        .clk            (clk),
        .frame_start    (frame_start),
        .pixel          (pixel),
        .pixel_value    (red_data)
    );
    deciderOfFate #(.BOARD_START(BLUE_START)) u5 (
        .clk            (clk),
        .frame_start    (frame_start),
        .pixel          (pixel),
        .pixel_value    (blue_data)
    );


    always_ff @(posedge clk) begin
        if (load_sreg) begin
            unique case ({ SW, BOOT })
                2'b00:
                    shift_reg <= { green_data, 16'd0 };
                2'b01:
                    shift_reg <= { 8'd0, red_data, 8'd0 };
                2'b10:
                    shift_reg <= { 16'd0, blue_data };
                2'b11:
                    shift_reg <= { green_data, red_data, blue_data };
            endcase
        end
        else if (shift) begin
            shift_reg <= { shift_reg[22:0], 1'b0 };
        end
    end

    assign _48b = ws2812b_out;
    assign _45a = ~ws2812b_out;

endmodule
