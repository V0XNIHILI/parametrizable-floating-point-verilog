`ifndef __RESULT_ROUNDER_V__
`define __RESULT_ROUNDER_V__

module result_rounder #(
    parameter int EXPONENT_WIDTH = 8,
    parameter int MANTISSA_WIDTH = 23,
    parameter int ROUND_TO_NEAREST_TIES_TO_EVEN = 1,  // 0: round to zero (chopping last bits), 1: round to nearest
    parameter int ROUNDING_BITS = 3  // Number of bits to use for rounding, should always be larger than 1, even for ROUND_TO_NEAREST_TIES_TO_EVEN = 0
) (
    input [EXPONENT_WIDTH-1:0] non_rounded_exponent,
    input [MANTISSA_WIDTH-1:0] non_rounded_mantissa,
    input [ROUNDING_BITS-1:0] rounding_bits,
    output reg [EXPONENT_WIDTH-1:0] rounded_exponent,
    output reg [MANTISSA_WIDTH-1:0] rounded_mantissa,
    output reg overflow_flag
);
    // Read-up on rounding: https://ee.usc.edu/~redekopp/cs356/slides/CS356Unit3_FP.pdf

    reg is_halfway;

    always_comb begin
        overflow_flag = 1'b0;
        rounded_mantissa = non_rounded_mantissa;
        rounded_exponent = non_rounded_exponent;

        if (ROUND_TO_NEAREST_TIES_TO_EVEN == 1) begin
            is_halfway = rounding_bits == {1'b1, {(ROUNDING_BITS - 1) {1'b0}}};

            // If the additonal mantissa bits are exactly halfway and if the last bit of the mantissa is 1
            // OR
            // if the additional bits are more than halfway,
            // round up
            if ((is_halfway && non_rounded_mantissa[0] == 1'b1) || (!is_halfway && rounding_bits[ROUNDING_BITS-1] == 1'b1)) begin
                $display("Rounding up.");

                rounded_mantissa = non_rounded_mantissa + 1;

                // If the mantissa has overflowed
                if (rounded_mantissa == 0) begin
                    $display("Mantissa has overflowed due to rounding.");

                    rounded_exponent = non_rounded_exponent + 1;

                    if (rounded_exponent == {EXPONENT_WIDTH{1'b1}}) begin
                        $display("Overflow detected during rounding.");

                        // Note: out_sign is already set
                        rounded_exponent = {EXPONENT_WIDTH{1'b1}};
                        rounded_mantissa = {MANTISSA_WIDTH{1'b0}};

                        overflow_flag = 1'b1;
                    end
                end
            end
            // Else, round down; nothing to do
        end
    end

endmodule

`endif
