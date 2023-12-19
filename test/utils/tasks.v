module tasks;

    integer total_tests = 0;
    integer tests_passed = 0;

    task check_equal;
        input integer expected;
        input integer actual;
        begin
            total_tests = total_tests + 1;

            assert (expected == actual) begin
                tests_passed = tests_passed + 1;
            end else begin
                $display("");
                $error("[!] Failed. Expected: %b, actual: %b", expected, actual);
            end
        end
    endtask

    task check_not_equal;
        input integer expected;
        input integer actual;
        begin
            assert (expected != actual) begin
                tests_passed = tests_passed + 1;
            end else begin
                $display("");
                $error("[!] Failed. Not expected: %b, actual: %b", expected, actual);
            end
        end
    endtask

    task check_greater;
        input integer expected;
        input integer actual;
        begin
            assert (actual > expected) begin
                tests_passed = tests_passed + 1;
            end else begin
                $display("");
                $error("[!] Failed. Expected %b to be greater than actual: %b", expected, actual);
            end
        end
    endtask

    task check_greater_equal;
        input integer expected;
        input integer actual;
        begin
            assert (actual >= expected) begin
                tests_passed = tests_passed + 1;
            end else begin
                $display("");
                $error("[!] Failed. Expected %b to be greater than or equal to actual: %b", expected, actual);
            end
        end
    endtask

    task check_less;
        input integer expected;
        input integer actual;
        begin
            assert (actual < expected) begin
                tests_passed = tests_passed + 1;
            end else begin
                $display("");
                $error("[!] Failed. Expected %b to be less than actual: %b", expected, actual);
            end
        end
    endtask

    task check_less_equal;
        input integer expected;
        input integer actual;
        begin
            assert (actual <= expected) begin
                tests_passed = tests_passed + 1;
            end else begin
                $display("");
                $error("[!] Failed. Expected %b to be less than or equal to actual: %b", expected, actual);
            end
        end
    endtask

endmodule
