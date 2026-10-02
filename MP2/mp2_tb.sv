`timescale 10ns/10ns
`include "mp2.sv"

module mp2_tb;

    parameter PWM_INTERVAL = 1200;

    logic clk = 0;
    logic RGB_R;
    logic RGB_G;
    logic RGB_B;

    top # (
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u0 (
        .clk            (clk),
        .RGB_R          (RGB_R),
        .RGB_G          (RGB_G),
        .RGB_B          (RGB_B)
    );

    initial begin
        $dumpfile("mp2.vcd");
        // Only dump the LED outputs and fade values; dumping every counter makes a huge file
        $dumpvars(0, RGB_R, RGB_G, RGB_B);
        $dumpvars(0, u0.r_pwm_value, u0.g_pwm_value, u0.b_pwm_value);
        #200000000      // 2 s of simulated time
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule
