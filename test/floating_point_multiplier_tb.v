`include "floating_point_multiplier.v"
`include "tasks.v"
`include "defines.vh"

module tb_floating_point_multiplier;
    // Parameters for the floating-point multiplier
    localparam EXPONENT_WIDTH = 8;
    localparam MANTISSA_WIDTH = 23;
    localparam FLOAT_BIT_WIDTH = EXPONENT_WIDTH + MANTISSA_WIDTH + 1;

    // Macro function to check the exception flags
    `define check_flags(uf, of, inv) \
    tasks.check_equal(uf, underflow_flag); \
    tasks.check_equal(of, overflow_flag); \
    tasks.check_equal(inv, invalid_operation_flag)

    // Signals for the multiplier and exception flags
    reg [FLOAT_BIT_WIDTH-1:0] a;
    reg [FLOAT_BIT_WIDTH-1:0] b;
    wire [FLOAT_BIT_WIDTH-1:0] out;
    wire underflow_flag;
    wire overflow_flag;
    wire invalid_operation_flag;


    `define steps 5
    reg [FLOAT_BIT_WIDTH*3-1:0] weights_per_step [`steps-1:0];

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
        $readmemb("../test/floats.bin", weights_per_step);

        `TEST_SUITE("Normal floating-point numbers") begin
            for (int i = 0; i < `steps; i = i + 1) begin
                `TEST_CASE("Try random floats") begin
                    a = weights_per_step[i][FLOAT_BIT_WIDTH*3-1:FLOAT_BIT_WIDTH*2];
                    b = weights_per_step[i][FLOAT_BIT_WIDTH*2-1:FLOAT_BIT_WIDTH];

                    #1;
                    
                    tasks.check_equal(weights_per_step[i][FLOAT_BIT_WIDTH-1:0], out);
                    `check_flags(0, 0, 0);
                end
            end

            `TEST_CASE("3.0 * 4.0 = 12.0") begin
                a = 32'h40400000; // 3.0
                b = 32'h40800000; // 4.0

                #1;

                tasks.check_equal(32'h41400000, out); // Expected: 12.0
                `check_flags(0, 0, 0);
            end

            `TEST_CASE("8.7 * 0.3 = 2.6100001") begin
                a = 32'h410B3333; // 8.7
                b = 32'h3E99999A; // 0.3

                #1;
                
                tasks.check_equal(32'h40270A3E, out); // Expected: 2.6100001
                 `check_flags(0, 0, 0);
            end

            `TEST_CASE("20003.0 * 0.1 = 2000.3") begin
                a = 32'h469C4600; // 20003.0
                b = 32'h3DCCCCCD; // 0.1

                #1;
                
                tasks.check_equal(32'h44FA099A, out); // Expected: 2000.3
                 `check_flags(0, 0, 0);
            end

            `TEST_CASE("0.0001 * 0.93 = 9.2999995E-5") begin
                a = 32'h38D1B717; // 0.0001
                b = 32'h3F6E147B; // 0.93

                #1;
                
                tasks.check_equal(32'h38C308FE, out); // Expected: 9.2999995E-5
                 `check_flags(0, 0, 0);
            end
        end

        `TEST_SUITE("Test denormalized numbers") begin
            `TEST_CASE("1.1754944E-38 ^ 2 = 0.0") begin
                a = 32'h00000001; // 1.1754944E-38
                b = 32'h00000001; // 1.1754944E-38

                #1;
                
                tasks.check_equal(32'h00000000, out); // Expected: 0.0 (underflow)
                `check_flags(1, 0, 0);
            end
        end

        `TEST_SUITE("Infinity") begin
            `TEST_CASE("+Inf * 3.0 = +Inf") begin
                a = 32'h7F800000; // +Inf
                b = 32'h40400000; // 3.0

                #1;
                
                tasks.check_equal(a, out); // Expected: +Inf
                `check_flags(0, 1, 0);
            end

            `TEST_CASE("+Inf * +Inf = +Inf") begin
                a = 32'h7F800000; // +Inf
                b = 32'h7F800000; // +Inf

                #1;
                
                tasks.check_equal(a, out); // Expected: +Inf
                `check_flags(0, 1, 0);
            end

            `TEST_CASE("-Inf * +Inf = -Inf") begin
                a = 32'hFF800000; // -Inf
                b = 32'h7F800000; // +Inf

                #1;
                
                tasks.check_equal(a, out); // Expected: -Inf
                `check_flags(0, 1, 0);
            end

            `TEST_CASE("-Inf * -Inf = +Inf") begin
                a = 32'hFF800000; // -Inf
                b = 32'hFF800000; // -Inf

                #1;
                
                tasks.check_equal(32'h7F800000, out); // Expected: +Inf
                `check_flags(0, 1, 0);
            end
        end

        `TEST_SUITE("NaN") begin
            `TEST_CASE("QNaN * 4.0 = QNaN") begin
                a = 32'hFFC00000; // QNaN
                b = 32'h40800000; // 4.0
                
                #1;
                
                tasks.check_equal(a, out); // Expected: QNaN
                `check_flags(0, 0, 1);
            end

            `TEST_CASE("SNaN * 4.0 = QNaN") begin
                a = 32'hFFA00000; // SNaN
                b = 32'h40800000; // 4.0

                #1;
                
                tasks.check_equal(32'hFFC00000, out); // Expected: QNaN
                `check_flags(0, 0, 1);
            end
        end

        `TEST_SUITE("Zeroes") begin
            `TEST_CASE("0.0 * 3.0 = 0.0") begin
                a = 32'h00000000; // 0.0
                b = 32'h40400000; // 3.0
                #1;
                
                tasks.check_equal(a, out); // Expected: 0.0
                 `check_flags(0, 0, 0);
            end

            `TEST_CASE("120 * 0.0 = 0.0") begin
                a = 32'h42F00000; // 120.0
                b = 32'h00000000; // 0.0
                #1;
                
                tasks.check_equal(b, out); // Expected: 0.0
                 `check_flags(0, 0, 0);
            end

            `TEST_CASE("QNaN * 0.0 = QNaN") begin
                a = 32'hFFC00000; // QNaN
                b = 32'h00000000; // 0.0
                #1;
                
                tasks.check_equal(a, out); // Expected: QNaN
                `check_flags(0, 0, 1);
            end

            `TEST_CASE("SNaN * 0.0 = QNaN") begin
                a = 32'hFFA00000; // SNaN
                b = 32'h00000000; // 0.0
                #1;
                
                tasks.check_equal(32'hFFC00000, out); // Expected: QNaN
                `check_flags(0, 0, 1);
            end
        end

        `ROUND_UP
    end
endmodule
