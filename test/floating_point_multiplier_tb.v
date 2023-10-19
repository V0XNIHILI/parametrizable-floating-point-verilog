`include "floating_point_multiplier.v"
`include "../tasks.v"

module tb_floating_point_multiplier;
    // Parameters for the floating-point multiplier
    localparam EXPONENT_WIDTH = 8;
    localparam MANTISSA_WIDTH = 23;
    localparam FLOAT_BIT_WIDTH = EXPONENT_WIDTH + MANTISSA_WIDTH + 1;

    // Signals for the multiplier and exception flags
    reg [FLOAT_BIT_WIDTH-1:0] a;
    reg [FLOAT_BIT_WIDTH-1:0] b;
    wire [FLOAT_BIT_WIDTH-1:0] out;
    wire underflow_flag;
    wire overflow_flag;
    wire invalid_operation_flag;

    // Instantiate the floating-point multiplier
    floating_point_multiplier #(EXPONENT_WIDTH, MANTISSA_WIDTH) uut (
        .a(a),
        .b(b),
        .out(out),
        .underflow_flag(underflow_flag),
        .overflow_flag(overflow_flag),
        .invalid_operation_flag(invalid_operation_flag)
    );

    // Test cases
    initial begin
        // Test normal floating-point numbers
        a = 32'h40400000; // 3.0
        b = 32'h40800000; // 4.0

        #1; tasks.print_if_failed(32'h41400000, out); // Expected: 12.0
        $display("\n- - -\n");

        a = 32'h410B3333; // 8.7
        b = 32'h3E99999A; // 0.3

        #1; tasks.print_if_failed(32'h40270A3E, out); // Expected: 2.6100001
        $display("\n- - -\n");

        a = 32'h469C4600; // 20003.0
        b = 32'h3DCCCCCD; // 0.1

        #1; tasks.print_if_failed(32'h44FA099A, out); // Expected: 2000.3
        $display("\n- - -\n");

        a = 32'h38D1B717; // 0.0001
        b = 32'h3F6E147B; // 0.93

        #1; tasks.print_if_failed(32'h38C308FE, out); // Expected: 9.2999995E-5
        $display("\n- - -\n");

        // Test denormalized numbers
        a = 32'h00000001; // 1.1754944E-38
        b = 32'h00000001; // 1.1754944E-38

        #1; tasks.print_if_failed(32'h00000000, out); // Expected: 0.0 (underflow)
        $display("\n- - -\n");

        // Test infinity
        a = 32'h7F800000; // +Inf
        b = 32'h40400000; // 3.0

        #1; tasks.print_if_failed(a, out); // Expected: +Inf
        $display("\n- - -\n");

        a = 32'h7F800000; // +Inf
        b = 32'h7F800000; // +Inf

        #1; tasks.print_if_failed(a, out); // Expected: +Inf
        $display("\n- - -\n");

        a = 32'h7F800000; // -Inf
        b = 32'h7F800000; // +Inf

        #1; tasks.print_if_failed(a, out); // Expected: -Inf
        $display("\n- - -\n");

        a = 32'h7F800000; // -Inf
        b = 32'h7F800000; // -Inf

        #1; tasks.print_if_failed(32'h7F800000, out); // Expected: +Inf
        $display("\n- - -\n");

        // Test NaN
        a = 32'hFFC00000; // QNaN
        b = 32'h40800000; // 4.0
        
        #1; tasks.print_if_failed(a, out); // Expected: NaN
        $display("\n- - -\n");

        a = 32'hFFA00000; // SNaN
        b = 32'h40800000; // 4.0

        #1; tasks.print_if_failed(32'hFFC00000, out); // Expected: NaN
        $display("\n- - -\n");

        // Test zero
        a = 32'h00000000; // 0.0
        b = 32'h40400000; // 3.0
        #1; tasks.print_if_failed(a, out); // Expected: 0.0
        $display("\n- - -\n");

        a = 32'h42F00000; // 120.0
        b = 32'h00000000; // 0.0
        #1; tasks.print_if_failed(b, out); // Expected: 0.0
        $display("\n- - -\n");

        a = 32'hFFC00000; // QNaN
        b = 32'h00000000; // 0.0
        #1; tasks.print_if_failed(a, out); // Expected: QNaN
        $display("\n- - -\n");

        a = 32'hFFA00000; // SNaN
        b = 32'h00000000; // 0.0
        #1; tasks.print_if_failed(32'hFFC00000, out); // Expected: QNaN
        $display("\n- - -\n");

        $display("All tests passed!");
    end
endmodule
