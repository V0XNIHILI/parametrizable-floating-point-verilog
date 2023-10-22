`include "leading_one_detector.v"
`include "tasks.v"
`include "defines.vh"

module tb_leading_one_detector;
    // Parameters for the leading one detector
    localparam WIDTH = 12;

    // Signals for the leading one detector
    reg [WIDTH-1:0] in;
    wire [$clog2(WIDTH)-1:0] position;
    wire has_leading_one;

    // Instantiate the leading one detector
    leading_one_detector #(WIDTH) uut (
        .in(in),
        .position(position),
        .has_leading_one(has_leading_one)
    );

    // Test cases
    initial begin
        `TEST_SUITE("Full zeroes with one 1") begin
            for (int i = 0; i < WIDTH; i = i + 1) begin
                `TEST_CASE("Try single one") begin
                    in = 0; #1; in[i] = 1'b1;

                    #1;

                    tasks.check_equal(i, position);
                    tasks.check_equal(1, has_leading_one);
                end
            end
        end

        `TEST_SUITE("Try input without one") begin
            `TEST_CASE("All zeroes") begin
                in = 0;

                #1;

                tasks.check_equal(0, has_leading_one);
            end
        end

        `ROUND_UP
    end
endmodule
