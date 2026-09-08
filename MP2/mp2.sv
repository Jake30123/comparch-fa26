`include "fade_with_off.sv"
`include "pwm.sv"

// Fade top level module

module top #(
    parameter PWM_INTERVAL = 1200       // CLK frequency is 12MHz, so 1,200 cycles is 100us
)(
    input logic     clk, 
    output logic    RGB_R,
    output logic    RGB_G,
    output logic    RGB_B
);
    // Light Control Variables
    logic [$clog2(PWM_INTERVAL) - 1:0] g_pwm_value;
    logic [$clog2(PWM_INTERVAL) - 1:0] b_pwm_value;
    logic [$clog2(PWM_INTERVAL) - 1:0] r_pwm_value;
    logic rgb_g_out;
    logic rgb_r_out;
    logic rgb_b_out;

    // Delay Variables
    parameter RED_DELAY = 4000000;
    parameter BLUE_DELAY = 8000000;
    logic [$clog2(BLUE_DELAY) - 1:0] count = 0;
    logic green_enable = 1'b0;
    logic red_enable = 1'b0;
    logic blue_enable = 1'b0;



    always_ff @(posedge clk) begin

        green_enable <= 1'b1;

        if (count >= RED_DELAY - 1) begin
            red_enable <= 1'b1;
        end
        if (count >= BLUE_DELAY - 1) begin
            blue_enable <= 1'b1;
        end
        if (count < BLUE_DELAY -1) begin
            count <= count + 1;
        end

    end

    fade #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) g1 (
        .clk            (clk), 
        .enable         (green_enable),
        .pwm_value      (g_pwm_value)
    );

    pwm #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) g2 (
        .clk            (clk), 
        .pwm_value      (g_pwm_value), 
        .pwm_out        (rgb_g_out)
    );

    fade #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) r1 (
        .clk            (clk), 
        .enable         (red_enable),
        .pwm_value      (r_pwm_value)
    );

    pwm #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) r2 (
        .clk            (clk), 
        .pwm_value      (r_pwm_value), 
        .pwm_out        (rgb_r_out)
    );

    fade #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) b1 (
        .clk            (clk), 
        .enable         (blue_enable),
        .pwm_value      (b_pwm_value)
    );

    pwm #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) b2 (
        .clk            (clk), 
        .pwm_value      (b_pwm_value), 
        .pwm_out        (rgb_b_out)
    );


    assign RGB_G = ~rgb_g_out;
    assign RGB_R = ~rgb_r_out;
    assign RGB_B = ~rgb_b_out;

endmodule
