`ifndef __FLOATING_POINT_ADDER_V__
`define __FLOATING_POINT_ADDER_V__

`include "is_special_float.v"
`include "leading_one_detector.v"
`include "result_rounder.v"

module floating_point_adder
    #(parameter int EXPONENT_WIDTH = 8,
      parameter int MANTISSA_WIDTH = 23,
      parameter int ROUND_TO_NEAREST = 1, // 0: round to zero (chopping last bits), 1: round to nearest
      parameter int ROUNDING_BITS = 3 // Number of bits to use for rounding, should always be larger than 1, even for ROUND_TO_NEAREST = 0
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

    localparam int TRUE_ROUNDING_BITS = ROUNDING_BITS * ROUND_TO_NEAREST;
    localparam int FLOAT_BIT_WIDTH = EXPONENT_WIDTH + MANTISSA_WIDTH + 1;

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
    reg signed [EXPONENT_WIDTH+2-1:0] temp_exponent;

    wire is_E4M3 = EXPONENT_WIDTH == 4 && MANTISSA_WIDTH == 3;

    // Special pre-defined values. {MANTISSA_WIDTH-1{...}} could also have been {MANTISSA_WIDTH-1{1'bX}}
    // but like this it explicitly supports the E4M3 variant.
    wire [FLOAT_BIT_WIDTH-1:0] quiet_nan = {1'b1, {EXPONENT_WIDTH{1'b1}}, 1'b1, {(MANTISSA_WIDTH-1){is_E4M3 ? 1'b1 : 1'b0}}};

    // Leading one detection

    wire [$clog2(MANTISSA_WIDTH+2+TRUE_ROUNDING_BITS)-1:0] leading_one_pos;
    wire has_leading_one;

    leading_one_detector #(.WIDTH(MANTISSA_WIDTH+2+TRUE_ROUNDING_BITS)) leading_one_detector_summed_mantissa
    (
        .in(positive_summed_mantissa),
        .position(leading_one_pos),
        .has_leading_one(has_leading_one)
    );

    // Find special float values

    wire is_a_infinite, is_b_infinite;
    wire is_a_zero, is_b_zero;
    wire is_signaling_nan_a, is_signaling_nan_b;
    wire is_quiet_nan_a, is_quiet_nan_b;

    is_special_float #(.EXPONENT_WIDTH(EXPONENT_WIDTH), .MANTISSA_WIDTH(MANTISSA_WIDTH)) is_special_float_a
    (
        .a(a),
        .is_infinite(is_a_infinite),
        .is_zero(is_a_zero),
        .is_signaling_nan(is_signaling_nan_a),
        .is_quiet_nan(is_quiet_nan_a)
    );

    is_special_float #(.EXPONENT_WIDTH(EXPONENT_WIDTH), .MANTISSA_WIDTH(MANTISSA_WIDTH)) is_special_float_b
    (
        .a(b),
        .is_infinite(is_b_infinite),
        .is_zero(is_b_zero),
        .is_signaling_nan(is_signaling_nan_b),
        .is_quiet_nan(is_quiet_nan_b)
    );

    // Rounding

    reg [MANTISSA_WIDTH-1:0] rounded_mantissa;
    reg [EXPONENT_WIDTH-1:0] rounded_exponent;
    reg rounded_overflow_flag;

    result_rounder #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH),
        .MANTISSA_WIDTH(MANTISSA_WIDTH),
        .ROUND_TO_NEAREST(ROUND_TO_NEAREST),
        .ROUNDING_BITS(ROUNDING_BITS)
    ) result_rounder_block (
        .non_rounded_exponent(temp_exponent),
        .non_rounded_mantissa(non_rounded_mantissa),
        .rounding_bits(additional_mantissa_bits),
        .rounded_exponent(rounded_exponent),
        .rounded_mantissa(rounded_mantissa),
        .overflow_flag(rounded_overflow_flag)
    );

    // Perform actual addition operation

    always @(*) begin
        underflow_flag = 1'b0;
        overflow_flag = 1'b0;
        invalid_operation_flag = 1'b0;

        if (is_signaling_nan_a || is_signaling_nan_b || is_quiet_nan_a || is_quiet_nan_b) begin
            $display("Result is QNaN due to one or both of the operands being NaN.");

            out = quiet_nan;

            if ((is_signaling_nan_a || is_signaling_nan_b) || ((is_quiet_nan_a && (!is_signaling_nan_b && !is_quiet_nan_b)) || (is_quiet_nan_b && (!is_signaling_nan_a && !is_quiet_nan_a)))) begin
                invalid_operation_flag = 1'b1;
            end
        // Cover: -Inf + +Inf = QNaN and +Inf - +Inf = QNaN
        end else if ((is_a_infinite && is_b_infinite) && ((!(a_sign && b_sign) && subtract) || (a_sign && !b_sign))) begin
            $display("Result is QNaN due to the fact that two opposite infinities were added.");

            out = quiet_nan;

            invalid_operation_flag = 1'b1;
        // Handle two special cases that otherwise are not correctly covered by the logic in the else block;
        // -Inf + -Inf = -Inf and +Inf + +Inf = +Inf
        end else if ((is_a_infinite && is_b_infinite) && !subtract && a_sign == b_sign) begin
            $display("Overflow detected.");

            out = {a_sign, {EXPONENT_WIDTH{1'b1}}, {MANTISSA_WIDTH{1'b0}}};

            overflow_flag = 1'b1;
        end else begin
            // Perform regular addition operation

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

            // At this line, summed_mantissa is always positive
            positive_summed_mantissa = summed_mantissa;

            // Multiply with has_leading_one to only shift if there is a leading 1
            normalized_mantissa = (positive_summed_mantissa >> (leading_one_pos-(MANTISSA_WIDTH+ROUNDING_BITS)));
            temp_exponent = out_exponent + (MANTISSA_WIDTH+TRUE_ROUNDING_BITS-leading_one_pos);

            if (temp_exponent < 0) begin
                $display("Underflow detected.");

                // Note: out_sign is already set
                out_exponent = 0;
                out_mantissa = 0;

                underflow_flag = 1'b1;
            end else if (temp_exponent >= {EXPONENT_WIDTH{1'b1}}) begin
                $display("Overflow detected.");

                // Note: out_sign is already set
                out_exponent = {EXPONENT_WIDTH{1'b1}};
                out_mantissa = {MANTISSA_WIDTH{1'b0}};

                overflow_flag = 1'b1;
            // In the normal case
            end else begin
                // These two values are fed into the result_rounder module
                non_rounded_mantissa = normalized_mantissa[MANTISSA_WIDTH+TRUE_ROUNDING_BITS-1:TRUE_ROUNDING_BITS];
                additional_mantissa_bits = normalized_mantissa[ROUNDING_BITS-1:0];

                // Then the result is rounded
                out_mantissa = rounded_mantissa;
                out_exponent = rounded_exponent;
                overflow_flag = rounded_overflow_flag;
            end

            out = {out_sign, out_exponent, out_mantissa};
        end
    end

endmodule

`endif
