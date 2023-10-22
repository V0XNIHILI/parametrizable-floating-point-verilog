# Parametrizable floating point operations in Verilog

This is a small library for floating point operations in Verilog. It is based on the IEEE 754-2008 standard for floating point arithmetic. The library currently supports addition/subtraction and multiplication of floating point numbers.

Compared to most other public floating point implementations in Verilog, this version has the following features:

- Fully parametrizable bit widths for exponent and mantissa
- Handles all special cases:
    - SNaN/QNaN
    - ± infinity
    - Denormalized numbers
    - Zeroes
- Single cycle operation
- Supports rounding to nearest (per official specification) or simply chopping bits

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

### [Floating-point conversion](src/floating_point_conversion.v)

```verilog
// TO DO!
```
