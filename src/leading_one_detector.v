`ifndef __LEADING_ONE_DETECTOR_V__
`define __LEADING_ONE_DETECTOR_V__

module leading_one_detector #(
    parameter int WIDTH = 8
) (
    input [WIDTH-1:0] value,
    output reg [$clog2(WIDTH)-1:0] position,
    output has_leading_one
);

    assign has_leading_one = value != 0;

    // Can also store boolean per bit, and then take the first true value in another loop

    genvar i;
    for (i = WIDTH - 1; i >= 0; i = i - 1) begin : gen_leading_one_detector_for_loop
        always_comb begin
            if (has_leading_one) begin
                if (value[i] == 1'b1 && (i == WIDTH - 1 ? 1'b1 : value[WIDTH-1:i] == 0)) begin
                    $display("Found leading one at position %d.", i);

                    position = i;
                end else begin
                    position = {$clog2(WIDTH){1'bz}};
                end
            end else begin
                $display("No leading one found.");

                position = {$clog2(WIDTH){1'bx}};
            end
        end
    end

endmodule

`endif
