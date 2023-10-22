`ifndef FLOATING_POINT_MULTIPLIER_V
`define FLOATING_POINT_MULTIPLIER_V

`include "is_special_float.v"

module floating_point_multiplier
    #(parameter EXPONENT_WIDTH = 8,
      parameter MANTISSA_WIDTH = 23,
      parameter ROUND_TO_NEAREST = 1 // 0: round to zero (chopping last bits), 1: round to nearest
    ) (
        input [EXPONENT_WIDTH+MANTISSA_WIDTH+1-1:0] a,
        input [EXPONENT_WIDTH+MANTISSA_WIDTH+1-1:0] b,
        output reg [EXPONENT_WIDTH+MANTISSA_WIDTH+1-1:0] out,

        // Exception flags
        output reg underflow_flag,
        output reg overflow_flag,
        output reg invalid_operation_flag
    );

    localparam FLOAT_BIT_WIDTH = EXPONENT_WIDTH + MANTISSA_WIDTH + 1;

    // Unpack input floats

    wire a_sign, b_sign;
    wire a_implicit_leading_bit, b_implicit_leading_bit;
    wire [EXPONENT_WIDTH-1:0] a_exponent, b_exponent;
    wire [MANTISSA_WIDTH-1:0] a_mantissa, b_mantissa;

    assign {a_sign, a_exponent, a_mantissa} = a;
    assign {b_sign, b_exponent, b_mantissa} = b;

    assign a_implicit_leading_bit = !(a_exponent == 0);
    assign b_implicit_leading_bit = !(b_exponent == 0);

    // Result variables
    reg out_sign;
    reg [EXPONENT_WIDTH-1:0] out_exponent;
    reg [MANTISSA_WIDTH-1:0] out_mantissa, non_rounded_mantissa;

    // Temporary variables
    reg [(MANTISSA_WIDTH+1)*2-1:0] a_mul_b_mantissa;
    reg [MANTISSA_WIDTH+1-1:0] additional_mantissa_bits;
    reg is_halfway;
    reg signed [EXPONENT_WIDTH+2-1:0] a_mul_b_exponent;
    reg leading_one_is_MSB;

    wire is_E4M3 = EXPONENT_WIDTH == 4 && MANTISSA_WIDTH == 3;

    // TODO: figure out how to support NaN for E2M3, E3M2 and E2M1 forrmats,
    // which all do not have NaNs defined.

    // Special pre-defined values. {MANTISSA_WIDTH-1{...}} could also have been {MANTISSA_WIDTH-1{1'bX}}
    // but like this it explicitly supports the E4M3 variant.
    wire [FLOAT_BIT_WIDTH-1:0] quiet_nan = {1'b1, {EXPONENT_WIDTH{1'b1}}, 1'b1, {(MANTISSA_WIDTH-1){is_E4M3 ? 1'b1 : 1'b0}}};
    wire [EXPONENT_WIDTH-1-1:0] bias = {(EXPONENT_WIDTH-1){1'b1}};

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

    // Perform actual multiplication operation

    always @(*) begin
        underflow_flag = 1'b0;
        overflow_flag = 1'b0;
        invalid_operation_flag = 1'b0;

        // TODO: handle subnormal numbers
        // TODO: make sure that all operations of special values are readily handled by the current code

        if (is_signaling_nan_a || is_signaling_nan_b || is_quiet_nan_a || is_quiet_nan_b) begin
            $display("Result is QNaN due to one or both of the operands being NaN.");

            out = quiet_nan;

            if ((is_signaling_nan_a || is_signaling_nan_b) || ((is_quiet_nan_a && (!is_signaling_nan_b && !is_quiet_nan_b)) || (is_quiet_nan_b && (!is_signaling_nan_a && !is_quiet_nan_a)))) begin
                invalid_operation_flag = 1'b1;
            end
        end else if ((is_a_zero && is_b_infinite) || (is_b_zero && is_a_infinite)) begin
            $display("Result is QNaN due to one of the operands being zero and the other being infinite.");

            out = quiet_nan;

            invalid_operation_flag = 1'b1;
        end else begin
            $display("Result is probably not QNaN.");

            out_sign = a_sign ^ b_sign;
            a_mul_b_mantissa = {a_implicit_leading_bit, a_mantissa} * {b_implicit_leading_bit, b_mantissa};
            a_mul_b_exponent = a_exponent + b_exponent - bias;

            leading_one_is_MSB = a_mul_b_mantissa[(MANTISSA_WIDTH+1)*2-1];

            // If the exponent is negative (first condition), the number is out of the IEEE 754
            // single precision normalized numbers range; in this case the output is signaled to 0
            // and an underflow flag is asserted. In the second case, the exponent is zero and it
            // cannot be compensated by normalization, so there is also an underflow.
            if (a_mul_b_exponent < 0 || (a_mul_b_exponent[EXPONENT_WIDTH+1-1:0] == 0 && leading_one_is_MSB == 1'b0)) begin
                $display("Underflow detected.");

                // Note: out_sign is already set
                out_exponent = 0;
                out_mantissa = 0;

                underflow_flag = 1'b1;
            // If overflow is detected. Overflow is present when the resulting exponent is equal to
            // or larger than 111...111 (all ones value with the same width as the exponent). For FP32,
            // this value is 255. Overflow can also occur when the exponent is equal to 111...110 and
            // +1 will be done for normalization, leading to 111...111: again, overflow.
            end else if (a_mul_b_exponent[EXPONENT_WIDTH+1-1:0] >= {EXPONENT_WIDTH{1'b1}} || (a_mul_b_exponent[EXPONENT_WIDTH-1:0] == ({EXPONENT_WIDTH{1'b1}}-1) && leading_one_is_MSB)) begin
                $display("Overflow detected.");

                // Note: out_sign is already set
                out_exponent = {EXPONENT_WIDTH{1'b1}};
                out_mantissa = {MANTISSA_WIDTH{1'b0}};

                overflow_flag = 1'b1;
            // In the normal case
            end else begin
                $display("No overflow or underflow detected.");

                // Note: out_sign is already set
                // Handle the special case where one of the inputs is zero: the output exponent
                // should then also be explicitly set to 0.
                out_exponent = (is_a_zero || is_b_zero) ? 0 : a_mul_b_exponent[EXPONENT_WIDTH-1:0] + (leading_one_is_MSB ? 1 : 0);
                non_rounded_mantissa = leading_one_is_MSB ? a_mul_b_mantissa[2*MANTISSA_WIDTH:MANTISSA_WIDTH+1] : a_mul_b_mantissa[2*MANTISSA_WIDTH-1:MANTISSA_WIDTH];
                additional_mantissa_bits = leading_one_is_MSB ? a_mul_b_mantissa[MANTISSA_WIDTH:0] : a_mul_b_mantissa[MANTISSA_WIDTH-1:0] << 1;

                out_mantissa = non_rounded_mantissa;

                if (ROUND_TO_NEAREST == 1) begin
                    is_halfway = additional_mantissa_bits == {1'b1, {MANTISSA_WIDTH{1'b0}}};

                    // If the additonal mantissa bits are exactly halfway and if the last bit of the mantissa is 1
                    // OR
                    // if the additional bits are more than halfway,
                    // round up
                    if ((is_halfway && non_rounded_mantissa[0] == 1'b1) || (!is_halfway && additional_mantissa_bits[MANTISSA_WIDTH] == 1'b1)) begin
                        // If the last bit of the mantissa is 1, round up
                        if (non_rounded_mantissa[0] == 1'b1) begin
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
                    // Else, round down; nothing to do
                end
            end

            out = {out_sign, out_exponent, out_mantissa};
        end
    end
endmodule

`endif