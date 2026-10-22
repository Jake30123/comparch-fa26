module deciderOfFate #(
    parameter INIT_FILE = "" // memh file with the starting board, one 8 bit row per line
)(
    input logic clk,
    input logic frame_start, // From controller 
    input logic [5:0] pixel, // What pixel we are on from controller
    output logic [7:0] pixel_value // Output value of just one color that we assign in top
);
    logic [2:0] col; // Column of current pixel
    logic [2:0] row; // Row of current pixel
    logic [2:0] col_l; //Left Neighbor indices, wrapped to 3 bits before indexing the board cuz of yosys extended math
    logic [2:0] col_r; // Right
    logic [2:0] row_u; // Up
    logic [2:0] row_d; // Down
    logic [7:0] neighbors_bin; // How many neighbors a cell has, each bit signifies one cell
    logic [4:0] neighbor_count; // Total number of neighbors 0 to 8 (includes corner cells)
    logic [7:0] neighbors_temp; // Temporary register to cut the critical path in half (90ns -> 45ns ish)

    logic [0:7] board_status [0:7]; // Matrix of current LED values, unpacked rows so $readmemh can load it
    logic [0:7] board_next [0:7]; // Matrix of upcoming LED values, unpacked to match board_status (iverilog can't write packed 2D with variable row index)

    logic reset; // Reset flag for writing board_next to board_status 


    initial begin
        $readmemh(INIT_FILE, board_status); // File chosen in top

        for (int i = 0; i < 8; i++) board_next[i] = '0; // Fill it full of zeros

        reset = 1'b0; // Reset not primed
    end


    always_comb begin
        col = pixel[2:0]; // Take the 3 least significant bits which represent the 0-7 columns
        row = pixel[5:3]; // Next three bits represent the rows

        // Forces wrap into 3 bit signal to avoid yosys extended math shenanigans
        col_l = col - 3'b001; // One column to the left or wrap
        col_r = col + 3'b001; // One row down or wrap
        row_u = row - 3'b001; // One row up or wrap
        row_d = row + 3'b001; // One column to the right or wrap

        // Calculate if a neighbor exists in a certain spot 0 = no, 1 = yes
        neighbors_bin[0] = board_status[row][col_l];     // Left
        neighbors_bin[1] = board_status[row][col_r];     // Right
        neighbors_bin[2] = board_status[row_u][col];     // Up
        neighbors_bin[3] = board_status[row_d][col];     // Down
        neighbors_bin[4] = board_status[row_u][col_l];   // Up to the left
        neighbors_bin[5] = board_status[row_u][col_r];   // Up to the right
        neighbors_bin[6] = board_status[row_d][col_l];   // Down to the left
        neighbors_bin[7] = board_status[row_d][col_r];   // Down to the right
    end

    always_ff @(posedge clk ) begin
        neighbors_temp <= neighbors_bin; // Aforementioned temporary register for critical path, store binary values for how many neighbors a single cell has
    end

    
    always_ff @(posedge clk) begin // Always one clock cycle behind since there is a temp register
        neighbor_count <= $countones(neighbors_temp); // Count the number of ones, each one is one neighbor

        if (board_status[row][col]) begin // If the cell is alive
            board_next[row][col] <= (neighbor_count == 2 || neighbor_count == 3); // Keep it alive if it has 2 or 3 neighbors, kill it otherwise
        end
        else begin // Else the cell is not alive
            board_next[row][col] <= (neighbor_count == 3); // Revive it if it has exactly 3 neighbors, otherwise, keep it dead
        end
    end

    always_ff @(posedge clk) begin // Always two clock cycles behind because of temp register and previous processing block
        if (frame_start) begin // If the frame is just starting (set by controller) write the new board status
            for (int i = 0; i < 8; i++) board_status[i] <= board_next[i]; // Row by row since board_status is unpacked
        end
    end

    always_comb begin // Determines pixel_value, the only value returned from this function
        if (board_status[row][col]) begin // If the cell is alive
            pixel_value = 8'b00000111; // Turn the pixel on
        end
        else begin // If not alive / dead
            pixel_value = 8'b00000000; // Turn the pixel off
        end
    end
endmodule 