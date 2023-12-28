import cocotb
from cocotb.triggers import Timer


def assert_flags(dut, flags):
    assert dut.underflow_flag.value == flags[0], "Underflow flag is not correct"
    assert dut.overflow_flag.value == flags[1], "Overflow flag is not correct"
    assert dut.invalid_operation_flag.value == flags[2], "Invalid operation flag is not correct"


async def check_input_combo(dut, a, b, subtract, expected, flags, assert_message, check_both_ways=True):
    for (a_entry, b_entry) in [(a, b), (b, a)] if check_both_ways and not subtract else [(a, b)]:
        dut.a.value = a_entry
        dut.b.value = b_entry
        dut.subtract.value = subtract

        await Timer(1, units="ns")
        assert_flags(dut, flags)
        assert dut.out.value == expected, assert_message

# TODO: test rounding bits
# TODO: test rounding or not

@cocotb.test()
async def test_normal_numbers(dut):
    await check_input_combo(dut, 0x40400000, 0x40800000, False, 0x40E00000, (0, 0, 0), "3.0 + 4.0 != 7.0")
    await check_input_combo(dut, 0x410B3333, 0x3E99999A, False, 0x41100000, (0, 0, 0), "8.7 + 0.3 != 9.0")
    await check_input_combo(dut, 0x469C4600, 0x3DCCCCCD, False, 0x469C4633, (0, 0, 0), "20003.0 + 0.1 != 20003.1")
    await check_input_combo(dut, 0x38D1B717, 0x3F6E147B, False, 0x3F6E1B09, (0, 0, 0), "0.0001 + 0.93 != 0.9301")


@cocotb.test()
async def test_infinity(dut):
    PLUS_INF = 0x7F800000
    NEG_INF = 0xFF800000
    QNAN = 0xFFC00000

    await check_input_combo(dut, PLUS_INF, 0x40400000, False, PLUS_INF, (0, 1, 0), "+Inf + 3.0 != +Inf")
    await check_input_combo(dut, PLUS_INF, PLUS_INF, False, PLUS_INF, (0, 1, 0), "+Inf + +Inf != +Inf")
    await check_input_combo(dut, NEG_INF, PLUS_INF, False, QNAN, (0, 0, 1), "-Inf + +Inf != QNaN")
    await check_input_combo(dut, PLUS_INF, NEG_INF, True, QNAN, (0, 0, 1), "+Inf - +Inf != QNaN")
    await check_input_combo(dut, NEG_INF, NEG_INF, False, NEG_INF, (0, 1, 0), "-Inf + -Inf = -Inf")


@cocotb.test()
async def test_zero(dut):
    ZERO = 0x00000000
    NEG_ZERO = 0x80000000
    QNAN = 0xFFC00000
    SNAN = 0xFFA00000

    await check_input_combo(dut, ZERO, 0x40400000, False, 0x40400000, (0, 0, 0), "0.0 + 3.0 != 3.0")
    await check_input_combo(dut, 0x42F00000, ZERO, False, 0x42F00000, (0, 0, 0), "120 + 0.0 != 120.0")
    await check_input_combo(dut, QNAN, ZERO, False, QNAN, (0, 0, 1), "QNaN + 0.0 != QNaN")
    await check_input_combo(dut, SNAN, ZERO, False, QNAN, (0, 0, 1), "SNaN + 0.0 != QNaN")
    await check_input_combo(dut, ZERO, NEG_ZERO, False, ZERO, (0, 0, 0), "+0 + -0 != +0")
    await check_input_combo(dut, ZERO, ZERO, False, ZERO, (0, 0, 0), "+0 + +0 != +0")
