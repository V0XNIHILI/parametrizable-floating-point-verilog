`ifndef __IS_SPECIAL_FLOAT_V__
`define __IS_SPECIAL_FLOAT_V__

module is_special_float #(
    parameter int EXPONENT_WIDTH = 8,
    parameter int MANTISSA_WIDTH = 23,
    parameter int IGNORE_SIGN_BIT_FOR_NAN = 1
) (
    input [EXPONENT_WIDTH+MANTISSA_WIDTH+1-1:0] a,
    output is_infinite,
    output is_zero,
    output is_subnormal,
    output is_signaling_nan,
    output is_quiet_nan
);

    // Taken from: https://www.semanticscholar.org/paper/Analysis-and-Research-of-Floating-Point-Exceptions-Hong-Chongyang/471be72eba3aca01cef4d979d4039691c0223235/figure/1

    wire sign;
    wire [EXPONENT_WIDTH-1:0] exponent;
    wire [MANTISSA_WIDTH-1:0] mantissa;

    assign {sign, exponent, mantissa} = a;

    // For a few variants (see here: https://www.opencompute.org/documents/ocp-microscaling-formats-mx-v1-0-spec-final-pdf)
    // there is special handling of NaN and infinite values. E5M2 fits inside the current handling
    // and therefore is not handled separately.
    wire is_E4M3 = EXPONENT_WIDTH == 4 && MANTISSA_WIDTH == 3;  // FP8
    wire is_E2M3 = EXPONENT_WIDTH == 2 && MANTISSA_WIDTH == 3;  // FP6
    wire is_E3M2 = EXPONENT_WIDTH == 3 && MANTISSA_WIDTH == 2;  // FP6
    wire is_E2M1 = EXPONENT_WIDTH == 2 && MANTISSA_WIDTH == 1;  // FP4

    // TODO: figure out which NaN to support for E4M3!
    // TODO: figure out how to deal with infinities and NaNs for E2M3, E3M2 and E2M1

    wire is_exponent_zero = (exponent == {EXPONENT_WIDTH{1'b0}});
    wire is_exponent_ones = (exponent == {EXPONENT_WIDTH{1'b1}});
    wire is_mantissa_zero = (mantissa == {MANTISSA_WIDTH{1'b0}});
    wire is_mantissa_ones = (mantissa == {MANTISSA_WIDTH{1'b1}});
    wire is_negative = sign == 1'b1;
    wire ignore_sign_bit_for_nan = IGNORE_SIGN_BIT_FOR_NAN == 1;

    // E2M3, E3M2 and E2M1 do not have infinite and NaN values.
    assign is_infinite = is_E4M3 || is_E2M3 || is_E3M2 || is_E2M1 ? 1'b0 : is_exponent_ones && is_mantissa_zero;
    assign is_zero = is_exponent_zero && is_mantissa_zero;
    assign is_subnormal = is_exponent_zero && !is_mantissa_zero;
    assign is_signaling_nan = is_E2M3 || is_E3M2 || is_E2M1 ? 1'b0 : (is_E4M3 ? is_exponent_ones && is_mantissa_ones : (is_negative || ignore_sign_bit_for_nan) && is_exponent_ones && (mantissa[MANTISSA_WIDTH-1] == 1'b1));
    assign is_quiet_nan = is_E4M3 || is_E2M3 || is_E3M2 || is_E2M1 ? 1'b0 : (is_negative || ignore_sign_bit_for_nan) && is_exponent_ones && (mantissa[MANTISSA_WIDTH-1] == 1'b0) && !is_mantissa_zero;
endmodule

`endif
