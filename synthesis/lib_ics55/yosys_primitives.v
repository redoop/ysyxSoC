// Yosys internal primitives for simulation

// D-Latch with positive enable
module \$_DLATCH_P_ (E, D, Q);
    input E, D;
    output reg Q;
    always @* if (E) Q <= D;
endmodule

// Tri-state buffer
module \$_TBUF_ (A, E, Y);
    input A, E;
    output Y;
    assign Y = E ? A : 1'bz;
endmodule

// Print statement (simulation only)
module \$print #(
    parameter ARGS_WIDTH = 1,
    parameter FORMAT = "",
    parameter PRIORITY = 0,
    parameter TRG_ENABLE = 0,
    parameter TRG_POLARITY = 0,
    parameter TRG_WIDTH = 1
) (
    input TRG,
    input EN,
    input [ARGS_WIDTH-1:0] ARGS
);
    // Empty module for synthesis compatibility
    // In simulation, this would print formatted output
endmodule
