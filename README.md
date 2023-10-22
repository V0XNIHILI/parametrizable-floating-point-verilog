# Parametrizable floating point operations in Verilog

Single-cycle floating-point adder and multiplier with parameters for exponent and mantissa bit widths, rounding, and support for all special cases (SNaN/QNaN, +-infinity, denormalized numbers, etc.).

## Usage

### [Floating-point adder](src/floating_point_adder.v)

```verilog
// your own module instantiation

    // Parameters for the floating-point adder
    localparam EXPONENT_WIDTH = 8;
    localparam MANTISSA_WIDTH = 23;
    localparam FLOAT_BIT_WIDTH = EXPONENT_WIDTH + MANTISSA_WIDTH + 1;

    // Inputs to the floating-point adder
    reg [FLOAT_BIT_WIDTH-1:0] a, b;
    reg subtract;

    // Outputs from the floating-point adder
    wire [FLOAT_BIT_WIDTH-1:0] out;
    wire underflow_flag, overflow_flag, invalid_operation_flag;

    // Instantiate the floating-point adder
    floating_point_adder #(EXPONENT_WIDTH, MANTISSA_WIDTH) fp_adder (
        .a(a),
        .b(b),
        .subtract(subtract),

        .out(out),
        .underflow_flag(underflow_flag),
        .overflow_flag(overflow_flag),
        .invalid_operation_flag(invalid_operation_flag)
    );

    // Can optionally disable rounding (enabled by default)

    localparam ROUND_TO_NEAREST = 0; // 0 = chop bits, 1 = round to nearest
    floating_point_adder #(EXPONENT_WIDTH, MANTISSA_WIDTH, ROUND_TO_NEAREST) fp_adder_no_rounding ( ... );

    // Can change number of bits for rounding (default is 3)

    localparam ROUNDING_BITS = 2;
    localparam ROUND_TO_NEAREST = 1;
    
    floating_point_adder #(EXPONENT_WIDTH, MANTISSA_WIDTH, ROUND_TO_NEAREST, ROUNDING_BITS) fp_adder_2bit_rounding ( ... );

// end of your own module instantiation
```

### [Floating-point multiplier](src/floating_point_multiplier.v)

```verilog
// your own module instantiation

    // Parameters for the floating-point adder
    localparam EXPONENT_WIDTH = 8;
    localparam MANTISSA_WIDTH = 23;
    localparam FLOAT_BIT_WIDTH = EXPONENT_WIDTH + MANTISSA_WIDTH + 1;

    // Inputs to the floating-point adder
    reg [FLOAT_BIT_WIDTH-1:0] a, b;

    // Outputs from the floating-point adder
    wire [FLOAT_BIT_WIDTH-1:0] out;
    wire underflow_flag, overflow_flag, invalid_operation_flag;

    // Instantiate the floating-point adder
    floating_point_adder #(EXPONENT_WIDTH, MANTISSA_WIDTH) fp_multiplier (
        .a(a),
        .b(b),

        .out(out),
        .underflow_flag(underflow_flag),
        .overflow_flag(overflow_flag),
        .invalid_operation_flag(invalid_operation_flag)
    );

    // Can optionally disable rounding (enabled by default)

    localparam ROUND_TO_NEAREST = 0; // 0 = chop bits, 1 = round to nearest
    floating_point_adder #(EXPONENT_WIDTH, MANTISSA_WIDTH, ROUND_TO_NEAREST) fp_multiplier_no_rounding ( ... );

// end of your own module instantiation
```
