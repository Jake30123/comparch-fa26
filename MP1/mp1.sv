// Blink

module top(
    input  logic  clk, 
    output logic  LED,
    output logic  RGB_R,
    output logic  RGB_B,
    output logic  RGB_G
);

    // CLK frequency is 12MHz, so 2,000,000 cycles is 0.2s
    parameter BLINK_INTERVAL = 2000000;
    parameter STATE = 7;
    logic [$clog2(BLINK_INTERVAL) - 1:0] count = 0;
    logic [$clog2(STATE):0] state = 1;

    initial begin
        LED = 1'b0;
        RGB_R = 1'b0;
        RGB_B = 1'b0;
        RGB_G = 1'b0;
    end

    always_ff @(posedge clk) begin
        if (count == BLINK_INTERVAL - 1) begin
            count <= 0;
            state <= state + 1;
        end
        else begin
            count <= count + 1;
        end

        if (state == 1) begin //RED
            RGB_R <= 0;
            RGB_B <= 1;
            RGB_G <= 1;
        end
        else if (state == 2) begin //YELLOW
            RGB_R <= 0;
            RGB_B <= 1;
            RGB_G <= 0;
        end
        else if (state == 3) begin //GREEN
            RGB_R <= 1;
            RGB_B <= 1;
            RGB_G <= 0;
        end
        else if (state == 4) begin //CYAN
            RGB_R <= 1;
            RGB_B <= 0;
            RGB_G <= 0;   
        end
        else if (state == 5) begin //BLUE
            RGB_R <= 1;
            RGB_B <= 0;
            RGB_G <= 1;     
        end
        else if (state == 6) begin //MAGENTA
            RGB_R <= 0;
            RGB_B <= 0;
            RGB_G <= 1;   
        end
        else begin
            state <= 1;
        end
    end

endmodule