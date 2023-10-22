`ifndef FLOATING_POINT_ADDER_V
`define FLOATING_POINT_ADDER_V

`include "is_special_float.v"
`include "leading_one_detector.v"

module floating_point_adder
    #(parameter EXPONENT_WIDTH = 8,
      parameter MANTISSA_WIDTH = 23,
      parameter ROUND_TO_NEAREST = 1, // 0: round to zero (chopping last bits), 1: round to nearest
      parameter ROUNDING_BITS = 3 // Number of bits to use for rounding, should always be larger than 1, even for ROUND_TO_NEAREST = 0
    ) (
        input [EXPONENT_WIDTH+MANTISSA_WIDTH+1-1:0] a,
        input [EXPONENT_WIDTH+MANTISSA_WIDTH+1-1:0] b,
        output reg [EXPONENT_WIDTH+MANTISSA_WIDTH+1-1:0] out,

        // Subtration flag
        input subtract,

        // Exception flags
        output reg underflow_flag,
        output reg overflow_flag,
        output reg invalid_operation_flag
    );

    localparam TRUE_ROUNDING_BITS = ROUNDING_BITS * ROUND_TO_NEAREST;
    localparam FLOAT_BIT_WIDTH = EXPONENT_WIDTH + MANTISSA_WIDTH + 1;

    // Unpack input floats

    wire a_sign, temp_b_sign, b_sign;
    wire a_implicit_leading_bit, b_implicit_leading_bit;
    wire [EXPONENT_WIDTH-1:0] a_exponent, b_exponent;
    wire [MANTISSA_WIDTH-1:0] a_mantissa, b_mantissa;

    assign {a_sign, a_exponent, a_mantissa} = a;
    assign {temp_b_sign, b_exponent, b_mantissa} = b;

    assign b_sign = subtract ? ~temp_b_sign : temp_b_sign;

    assign a_implicit_leading_bit = !(a_exponent == 0);
    assign b_implicit_leading_bit = !(b_exponent == 0);

    // Result variables
    reg out_sign;
    reg [EXPONENT_WIDTH-1:0] out_exponent;
    reg [MANTISSA_WIDTH-1:0] out_mantissa;

    // Temporary variables
    reg signed [EXPONENT_WIDTH+1-1:0] exponent_difference;
    reg [EXPONENT_WIDTH-1:0] abs_exponent_difference;
    reg [MANTISSA_WIDTH+1+TRUE_ROUNDING_BITS-1:0] a_shifted_mantissa; // TRUE_ROUNDING_BITS extra bits for rounding
    reg [MANTISSA_WIDTH+1+TRUE_ROUNDING_BITS-1:0] b_shifted_mantissa; // TRUE_ROUNDING_BITS extra bits for rounding
    reg signed [MANTISSA_WIDTH+2+TRUE_ROUNDING_BITS+1-1:0] summed_mantissa;
    reg [MANTISSA_WIDTH+2+TRUE_ROUNDING_BITS-1:0] positive_summed_mantissa;
    reg [MANTISSA_WIDTH+2+TRUE_ROUNDING_BITS-1:0] normalized_mantissa;
    reg [MANTISSA_WIDTH-1:0] non_rounded_mantissa;
    reg [ROUNDING_BITS-1:0] additional_mantissa_bits;
    wire [$clog2(MANTISSA_WIDTH+2+TRUE_ROUNDING_BITS)-1:0] leading_one_pos;
    reg is_halfway;

    leading_one_detector #(.WIDTH(MANTISSA_WIDTH+2+TRUE_ROUNDING_BITS)) leading_one_detector_summed_mantissa
    (
        .in(positive_summed_mantissa),
        .position(leading_one_pos)
    );    

    always @(*) begin
        exponent_difference = a_exponent - b_exponent;
        out_sign = 1'b0;

        a_shifted_mantissa = {a_implicit_leading_bit, a_mantissa} << TRUE_ROUNDING_BITS;
        b_shifted_mantissa = {b_implicit_leading_bit, b_mantissa} << TRUE_ROUNDING_BITS;
        
        if (exponent_difference >= 0) begin
            $display("A exponent is bigger than B exponent");

            abs_exponent_difference = exponent_difference;
            out_exponent = a_exponent;
            b_shifted_mantissa = b_shifted_mantissa >> abs_exponent_difference;
        end else begin
            $display("B exponent is bigger than A exponent");

            abs_exponent_difference = -exponent_difference;
            out_exponent = b_exponent;
            a_shifted_mantissa = a_shifted_mantissa >> abs_exponent_difference;
        end

        if (a_sign == 1'b0 && b_sign == 1'b0) begin
            summed_mantissa = a_shifted_mantissa + b_shifted_mantissa;
            out_sign = 1'b0;
        end else if (a_sign == 1'b1) begin
            summed_mantissa = b_shifted_mantissa - a_shifted_mantissa;
        end else if (b_sign == 1'b1) begin
            summed_mantissa = a_shifted_mantissa - b_shifted_mantissa;
        end

        if ((a_sign || b_sign) && summed_mantissa < 0) begin
            summed_mantissa = -summed_mantissa;
            out_sign = 1'b1;
        end

        positive_summed_mantissa = summed_mantissa;

        if (positive_summed_mantissa != 0) begin
            normalized_mantissa = (positive_summed_mantissa >> (leading_one_pos-(MANTISSA_WIDTH+ROUNDING_BITS)));
            out_exponent = out_exponent + (MANTISSA_WIDTH+TRUE_ROUNDING_BITS-leading_one_pos);

            non_rounded_mantissa = normalized_mantissa[MANTISSA_WIDTH+TRUE_ROUNDING_BITS-1:TRUE_ROUNDING_BITS];
            additional_mantissa_bits = normalized_mantissa[ROUNDING_BITS-1:0];

            out_mantissa = non_rounded_mantissa;

            if (ROUND_TO_NEAREST == 1) begin
                is_halfway = additional_mantissa_bits == {1'b1, {(ROUNDING_BITS-1){1'b0}}};

                // If the additonal mantissa bits are exactly halfway and if the last bit of the mantissa is 1
                // OR
                // if the additional bits are more than halfway,
                // round up
                if ((is_halfway && non_rounded_mantissa[0] == 1'b1) || (!is_halfway && additional_mantissa_bits[ROUNDING_BITS-1] == 1'b1)) begin
                    $display("Rounding up.");

                    out_mantissa = non_rounded_mantissa + 1;

                    // If the mantissa has overflowed
                    if (out_mantissa == 0) begin
                        $display("Mantissa has overflowed due to rounding.");

                        out_exponent = out_exponent + 1;

                        if (out_exponent == {EXPONENT_WIDTH{1'b1}}) begin
                            $display("Overflow detected.");

                            // Note: out_sign is already set
                            out_exponent = {EXPONENT_WIDTH{1'b1}};
                            out_mantissa = {MANTISSA_WIDTH{1'b0}};

                            overflow_flag = 1'b1;
                        end
                    end
                end
                // Else, round down; nothing to do
            end
        end

        out = {out_sign, out_exponent, out_mantissa};

        underflow_flag = 1'b0;
        overflow_flag = 1'b0;
        invalid_operation_flag = 1'b0;
    end

endmodule

`endif
