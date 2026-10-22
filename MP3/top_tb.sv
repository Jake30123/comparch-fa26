`timescale 10ns/10ns
`include "top.sv"

// Prints the red, green, and blue boards for the first 5 frames

module top_tb;

    logic clk = 0;
    logic _48b;
    logic _45a;

    top u0 ( // Instance top
        .clk    (clk),
        .SW     (1'b1),
        .BOOT   (1'b1),
        ._48b   (_48b),
        ._45a   (_45a)
    );

    initial begin
        #1
        for (int f = 0; f < 5; f++) begin // Only go for first 5 frames
            if (f > 0) begin
                do @(posedge clk); // Board updates on this edge
                while (!u0.u2.idle_done); 
                @(negedge clk);
            end
            $display("\nFrame %0d\nred", f);
            for (int row = 0; row < 8; row++)
                $display("%b", u0.u4.board_status[row]);
        end
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule
