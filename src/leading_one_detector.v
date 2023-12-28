`ifndef __LEADING_ONE_DETECTOR_V__
`define __LEADING_ONE_DETECTOR_V__

module leading_one_detector #(
    parameter int WIDTH = 8
) (
    input [WIDTH-1:0] value,
    output reg [$clog2(WIDTH)-1:0] position,
    output reg has_leading_one
);

    integer i;

    // Required to support Icarus Verilog
    reg stop_bit;

    always_comb begin
        position = {$clog2(WIDTH) {1'bx}};
        has_leading_one = value != 0;
        stop_bit = 1'b0;

        for (i = WIDTH - 1; i >= 0; i = i - 1) begin
            if (value[i] == 1'b1 && stop_bit == 1'b0) begin
                // Index selection to avoid the error:
                // "Operator ASSIGN expects 5 bits on the Assign RHS, but Assign RHS's VARREF 'i' generates 32 bits."
                // from Verilator.
                position = i[$clog2(WIDTH)-1:0];

                $display("Found leading one at position %d", position);

`ifdef __ICARUS__
                stop_bit = 1'b1;
`else
                break;
`endif
            end
        end
    end

endmodule

`endif
