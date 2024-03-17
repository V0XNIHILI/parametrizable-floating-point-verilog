`ifndef __FLOATING_POINT_MULTIPLIER_ADDER_V__
`define __FLOATING_POINT_MULTIPLIER_ADDER_V__

`include "floating_point_adder.v"
`include "floating_point_multiplier.v"

module floating_point_multiplier_adder #(
    parameter int EXPONENT_WIDTH = 8,
    parameter int MANTISSA_WIDTH = 23,
    parameter int ROUND_TO_NEAREST_TIES_TO_EVEN = 1,  // 0: round to zero (chopping last bits), 1: round to nearest
    parameter int IGNORE_SIGN_BIT_FOR_NAN = 1,
    localparam int FloatBitWidth = EXPONENT_WIDTH + MANTISSA_WIDTH + 1
) (
    input [FloatBitWidth-1:0] a_1,
    input [FloatBitWidth-1:0] a_2,
    input [FloatBitWidth-1:0] b,
    output [FloatBitWidth-1:0] out
);

    wire [FloatBitWidth-1:0] multiplication_result;

    floating_point_multiplier #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH),
        .MANTISSA_WIDTH(MANTISSA_WIDTH),
        .ROUND_TO_NEAREST_TIES_TO_EVEN(ROUND_TO_NEAREST_TIES_TO_EVEN),
        .IGNORE_SIGN_BIT_FOR_NAN(IGNORE_SIGN_BIT_FOR_NAN)
    ) multiplier (
        .a(a_1),
        .b(a_2),
        .out(multiplication_result)
    );

    floating_point_adder #(
        .EXPONENT_WIDTH(EXPONENT_WIDTH),
        .MANTISSA_WIDTH(MANTISSA_WIDTH),
        .ROUND_TO_NEAREST_TIES_TO_EVEN(ROUND_TO_NEAREST_TIES_TO_EVEN),
        .IGNORE_SIGN_BIT_FOR_NAN(IGNORE_SIGN_BIT_FOR_NAN)
    ) adder (
        .a(multiplication_result),
        .b(b),
        .out(out)
    );

endmodule

`endif
