`define TEST_CASE(description) \
$display("\nCase - ", description); \
$display("----------------------------------------"); \
if(1 == 1)

`define TEST_SUITE(description) \
$display("\n\nSuite - ", description); \
$display("========================================"); \
if(1 == 1)

`define ROUND_UP \
if (tasks.tests_passed == tasks.total_tests) begin \
    $display("\n\n+--------------------------------------+"); \
    $display("[V] Passed all tests: %0d/%0d", tasks.tests_passed, tasks.total_tests); \
    $display("+--------------------------------------+"); \
end else begin \
    $display("\n\n+--------------------------------------+"); \
    $display("[X] Failed some tests: %0d/%0d", tasks.tests_passed, tasks.total_tests); \
    $display("+--------------------------------------+"); \
    $stop; \
end
