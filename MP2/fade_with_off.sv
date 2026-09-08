// Fade
// Re-written from examples to include an OFF state
// Speed of fade has also been reduced

module fade #(
    parameter INC_DEC_INTERVAL = 12000,     // CLK frequency is 12MHz, so 12,000 cycles is 1ms
    parameter INC_DEC_MAX = 167,            // Rise or fall for 167 increments / decrements, which is 0.167s
    parameter PWM_INTERVAL = 1200,          // CLK frequency is 12MHz, so 1,200 cycles is 100us
    parameter INC_DEC_VAL = PWM_INTERVAL / INC_DEC_MAX
)(
    input logic clk, 
    input logic enable,
    output logic [$clog2(PWM_INTERVAL) - 1:0] pwm_value
);

    // Define state variable values
    localparam PWM_INC = 2'b00;
    localparam PWM_DEC = 2'b01;
    localparam PWM_OFF = 2'b10;
    localparam PWM_ON  = 2'b11;

    // Declare state variables
    logic [1:0] current_state = PWM_OFF;
    logic [1:0] next_state;

    // Declare variables for timing state transitions
    logic [$clog2(INC_DEC_INTERVAL) - 1:0] count = 0;
    logic [$clog2(INC_DEC_MAX) - 1:0] inc_dec_count = 0;
    logic time_to_inc_dec = 1'b0;
    logic time_to_transition = 1'b0;
    logic switch_time = 1'b0;

    initial begin
        pwm_value = 0;
    end

    // Register the next state of the FSM
    always_ff @(posedge time_to_transition) begin
        if (current_state == PWM_OFF || current_state == PWM_ON) begin
            if (switch_time == 1) begin
                current_state <= next_state;
                switch_time <= 0;
            end
            else begin
                switch_time <= 1;
            end
        end
        else begin
            current_state <= next_state;
        end
    end



    // Compute the next state of the FSM
    always_comb begin
        next_state = 2'bxx;
        case (current_state)
            PWM_INC:
                next_state = PWM_ON;
            PWM_DEC:
                next_state = PWM_OFF;
            PWM_OFF:
                next_state = PWM_INC;
            PWM_ON:
                next_state = PWM_DEC;
        endcase
    end

    // Implement counter for incrementing / decrementing PWM value
    always_ff @(posedge clk) begin
        if (count == INC_DEC_INTERVAL - 1 && enable) begin
            count <= 0;
            time_to_inc_dec <= 1'b1;
        end
        else if (enable) begin
            count <= count + 1;
            time_to_inc_dec <= 1'b0;
        end
        else begin
            time_to_inc_dec <= 1'b0;
        end
    end

    // Increment / Decrement PWM value as appropriate given current state
    always_ff @(posedge time_to_inc_dec) begin
        case (current_state)
            PWM_INC:
                pwm_value <= pwm_value + INC_DEC_VAL;
            PWM_DEC:
                pwm_value <= pwm_value - INC_DEC_VAL;
            PWM_OFF:
                pwm_value <= 0;
            PWM_ON:
                pwm_value <= PWM_INTERVAL;
        endcase
    end

    // Implement counter for timing state transitions
    always_ff @(posedge time_to_inc_dec) begin
        if (inc_dec_count == INC_DEC_MAX - 1) begin
            inc_dec_count <= 0;
            time_to_transition <= 1'b1;
        end
        else begin
            inc_dec_count <= inc_dec_count + 1;
            time_to_transition <= 1'b0;
        end
    end

endmodule
