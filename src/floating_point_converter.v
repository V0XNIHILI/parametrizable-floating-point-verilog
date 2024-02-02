`ifndef __FLOATING_POINT_CONVERSION_V__
`define __FLOATING_POINT_CONVERSION_V__

`include "is_special_float.v"

`define min_op(v1, v2) ((v1) > (v2) ? (v2) : (v1))

module floating_point_converter
    #(parameter int IN_EXPONENT_WIDTH = 8,
      parameter int IN_MANTISSA_WIDTH = 23,
      parameter int OUT_EXPONENT_WIDTH = 11,
      parameter int OUT_MANTISSA_WIDTH = 52,
      parameter int ROUND_TO_NEAREST = 1, // 0: round to zero (chopping last bits), 1: round to nearest
      parameter int ROUNDING_BITS = 3 // Number of bits to use for rounding, should always be larger than 1, even for ROUND_TO_NEAREST = 0
    ) (
        input [IN_EXPONENT_WIDTH+IN_MANTISSA_WIDTH+1-1:0] in,
        output reg [OUT_EXPONENT_WIDTH+OUT_MANTISSA_WIDTH+1-1:0] out,

        // Exception flags
        output reg underflow_flag,
        output reg overflow_flag,
        output reg invalid_operation_flag
    );

    localparam int RequiredMantissaShift = IN_MANTISSA_WIDTH - OUT_MANTISSA_WIDTH;
    localparam TrueRoundingBIts = `min_op(RequiredMantissaShift * (IN_MANTISSA_WIDTH > OUT_MANTISSA_WIDTH), ROUNDING_BITS);

    // Result variables
    reg out_sign;
    reg [OUT_EXPONENT_WIDTH-1:0] out_exponent;
    reg [OUT_MANTISSA_WIDTH-1:0] out_mantissa;

    // Unpack input float

    wire in_sign;
    wire in_implicit_leading_bit;
    wire [IN_EXPONENT_WIDTH-1:0] in_exponent;
    wire [IN_MANTISSA_WIDTH-1:0] in_mantissa;

    assign {in_sign, in_exponent, in_mantissa} = in;

    assign in_implicit_leading_bit = !(in_exponent == 0);

    // Temporary variables

    reg [OUT_EXPONENT_WIDTH+1-1:0] non_rounded_exponent;
    reg [OUT_MANTISSA_WIDTH+1-1:0] non_rounded_mantissa;
    reg [TrueRoundingBIts-1:0] additional_mantissa_bits;

    reg signed [IN_EXPONENT_WIDTH+OUT_EXPONENT_WIDTH+1-1:0] exponent_difference;

    wire [IN_EXPONENT_WIDTH-1-1:0] in_bias = {(IN_EXPONENT_WIDTH-1){1'b1}};
    wire [OUT_EXPONENT_WIDTH-1-1:0] out_bias = {(OUT_EXPONENT_WIDTH-1){1'b1}};

    // Find special float values

    wire is_in_infinite;
    wire is_in_zero;
    wire is_signaling_nan_in;
    wire is_quiet_nan_in;

    is_special_float #(.EXPONENT_WIDTH(IN_EXPONENT_WIDTH), .MANTISSA_WIDTH(IN_MANTISSA_WIDTH)) is_special_float_in
    (
        .a(in),
        .is_infinite(is_in_infinite),
        .is_zero(is_in_zero),
        .is_signaling_nan(is_signaling_nan_in),
        .is_quiet_nan(is_quiet_nan_in)
    );

    // Rounding

    reg [OUT_MANTISSA_WIDTH-1:0] rounded_mantissa;
    reg [OUT_EXPONENT_WIDTH-1:0] rounded_exponent;
    reg rounded_overflow_flag;

    result_rounder #(OUT_EXPONENT_WIDTH, OUT_MANTISSA_WIDTH, ROUND_TO_NEAREST, TrueRoundingBIts) result_rounder_block
    (
        .non_rounded_exponent(non_rounded_exponent),
        .non_rounded_mantissa(non_rounded_mantissa),
        .rounding_bits(additional_mantissa_bits),
        .rounded_exponent(rounded_exponent),
        .rounded_mantissa(rounded_mantissa),
        .overflow_flag(rounded_overflow_flag)
    );

    // Perform actual conversion operation

    always_comb begin
        underflow_flag = 1'b0;
        overflow_flag = 1'b0;
        invalid_operation_flag = 1'b0;

        out_sign = in_sign;

        if (is_in_zero) begin
            {out_exponent, out_mantissa} = 0;
        end else if (is_in_infinite) begin
            {out_exponent, out_mantissa} = {OUT_EXPONENT_WIDTH{1'b1}, OUT_MANTISSA_WIDTH{1'b0}};

            overflow_flag = 1'b1;
        end else if (is_signaling_nan_in) begin
            // TODO!
            {out_exponent, out_mantissa} = {OUT_EXPONENT_WIDTH{1'b1}, (OUT_MANTISSA_WIDTH-1){1'b1}};

            invalid_operation_flag = 1'b1;
        end else if (is_quiet_nan_in) begin
            // TODO!
            {out_exponent, out_mantissa} = {OUT_EXPONENT_WIDTH{1'b1}, (OUT_MANTISSA_WIDTH-1){1'b1}};

            invalid_operation_flag = 1'b1;
        end else begin
            exponent_difference = in_exponent - in_bias + out_bias;

            if (exponent_difference < 0) begin
                $display("Underflow detected during conversion.");

                // Note: out_sign is already set
                out_exponent = 0;
                out_mantissa = 0;

                underflow_flag = 1'b1;
            end else if (exponent_difference >= OUT_EXPONENT_WIDTH{1'b1}) begin
                $display("Overflow detected during conversion.");

                // Note: out_sign is already set
                out_exponent = {EXPONENT_WIDTH{1'b1}};
                out_mantissa = {MANTISSA_WIDTH{1'b0}};

                overflow_flag = 1'b1;
            end else begin
                non_rounded_exponent = exponent_difference[OUT_EXPONENT_WIDTH-1:0];
                non_rounded_mantissa = in_mantissa >> RequiredMantissaShift;

                if (OUT_MANTISSA_WIDTH < IN_MANTISSA_WIDTH) begin
                    additional_mantissa_bits = in_mantissa[TrueRoundingBIts-1:0];

                    out_exponent = rounded_exponent;
                    out_mantissa = rounded_mantissa;
                end else begin
                    out_exponent = non_rounded_exponent;
                    out_mantissa = non_rounded_mantissa;
                end
            end
        end

        out = {out_sign, out_exponent, out_mantissa};
    end

endmodule

`endif
