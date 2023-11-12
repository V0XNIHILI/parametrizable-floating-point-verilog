`include "floating_point_adder.v"
`include "tasks.v"
`include "defines.vh"

module tb_floating_point_adder;
    // Parameters for the floating-point adder
    localparam ExponentWidth = 8;
    localparam MantissaWidth = 23;
    localparam FloatBitWidth = ExponentWidth + MantissaWidth + 1;

    // Macro function to check the exception flags
    `define check_flags(uf, of, inv) \
    tasks.check_equal(uf, underflow_flag); \
    tasks.check_equal(of, overflow_flag); \
    tasks.check_equal(inv, invalid_operation_flag)

    // Signals for the multiplier and exception flags
    reg [FloatBitWidth-1:0] a;
    reg [FloatBitWidth-1:0] b;
    reg subtract;
    wire [FloatBitWidth-1:0] out;
    wire underflow_flag;
    wire overflow_flag;
    wire invalid_operation_flag;

    // Instantiate the floating-point multiplier
    floating_point_adder #(ExponentWidth, MantissaWidth) uut (
        .a(a),
        .b(b),
        .subtract(subtract),
        .out(out),
        .underflow_flag(underflow_flag),
        .overflow_flag(overflow_flag),
        .invalid_operation_flag(invalid_operation_flag)
    );

    // Test cases
    initial begin

        `TEST_SUITE("Normal floating-point numbers") begin

            `TEST_CASE("3.0 + 4.0 = 7.0") begin
                a = 32'h40400000; // 3.0
                b = 32'h40800000; // 4.0
                subtract = 0;

                #1;

                tasks.check_equal(32'h40E00000, out); // Expected: 7.0
                `check_flags(0, 0, 0);
            end

            `TEST_CASE("8.7 + 0.3 = 9.0") begin
                a = 32'h410B3333; // 8.7
                b = 32'h3E99999A; // 0.3
                subtract = 0;

                #1;
                
                tasks.check_equal(32'h41100000, out); // 9.0
                 `check_flags(0, 0, 0);
            end

            `TEST_CASE("20003.0 + 0.1 = 20003.1") begin
                a = 32'h469C4600; // 20003.0
                b = 32'h3DCCCCCD; // 0.1
                subtract = 0;

                #1;
                
                tasks.check_equal(32'h469C4633, out); // Expected: 20003.1
                 `check_flags(0, 0, 0);
            end

            `TEST_CASE("0.0001 + 0.93 = 0.9301") begin
                a = 32'h38D1B717; // 0.0001
                b = 32'h3F6E147B; // 0.93
                subtract = 0;

                #1;
                
                tasks.check_equal(32'h3F6E1B09, out); // Expected: 0.9301
                 `check_flags(0, 0, 0);
            end
        end

        `TEST_SUITE("Infinity") begin
            `TEST_CASE("+Inf + 3.0 = +Inf") begin
                a = 32'h7F800000; // +Inf
                b = 32'h40400000; // 3.0
                subtract = 0;

                #1;
                
                tasks.check_equal(a, out); // Expected: +Inf
                `check_flags(0, 1, 0);
            end

            `TEST_CASE("+Inf + +Inf = +Inf") begin
                a = 32'h7F800000; // +Inf
                b = 32'h7F800000; // +Inf
                subtract = 0;

                #1;
                
                tasks.check_equal(a, out); // Expected: +Inf
                `check_flags(0, 1, 0);
            end

            `TEST_CASE("-Inf + +Inf = QNaN") begin
                a = 32'hFF800000; // -Inf
                b = 32'h7F800000; // +Inf
                subtract = 0;

                #1;
                
                tasks.check_equal(32'hFFC00000, out); // Expected: QNaN
                `check_flags(0, 0, 1);
            end

            `TEST_CASE("+Inf - +Inf = QNaN") begin
                a = 32'h7F800000; // +Inf
                b = 32'h7F800000; // +Inf
                subtract = 1;

                #1;
                
                tasks.check_equal(32'hFFC00000, out); // Expected: QNaN
                `check_flags(0, 0, 1);
            end            

            `TEST_CASE("-Inf + -Inf = -Inf") begin
                a = 32'hFF800000; // -Inf
                b = 32'hFF800000; // -Inf
                subtract = 0;

                #1;
                
                tasks.check_equal(a, out); // Expected: -Inf
                `check_flags(0, 1, 0);
            end
        end

        `TEST_SUITE("Zeroes") begin
            `TEST_CASE("0.0 + 3.0 = 3.0") begin
                a = 32'h00000000; // 0.0
                b = 32'h40400000; // 3.0
                #1;
                
                tasks.check_equal(b, out); // Expected: 3.0
                 `check_flags(0, 0, 0);
            end

            `TEST_CASE("120 + 0.0 = 120.0") begin
                a = 32'h42F00000; // 120.0
                b = 32'h00000000; // 0.0
                #1;
                
                tasks.check_equal(a, out); // Expected: 12.0
                 `check_flags(0, 0, 0);
            end

            `TEST_CASE("QNaN + 0.0 = QNaN") begin
                a = 32'hFFC00000; // QNaN
                b = 32'h00000000; // 0.0
                #1;
                
                tasks.check_equal(a, out); // Expected: QNaN
                `check_flags(0, 0, 1);
            end

            `TEST_CASE("SNaN + 0.0 = QNaN") begin
                a = 32'hFFA00000; // SNaN
                b = 32'h00000000; // 0.0
                #1;
                
                tasks.check_equal(32'hFFC00000, out); // Expected: QNaN
                `check_flags(0, 0, 1);
            end

            `TEST_CASE("+0 + -0 = +0") begin
                a = 32'h00000000; // +0
                b = 32'h80000000; // -0
                #1;
                
                tasks.check_equal(a, out); // Expected: +0
                 `check_flags(0, 0, 0);
            end
        end        

        `ROUND_UP
    end
endmodule
