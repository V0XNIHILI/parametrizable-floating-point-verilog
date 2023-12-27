import cocotb
from cocotb.triggers import Timer


def assert_flags(dut, flags):
    assert dut.underflow_flag.value == flags[0], "Underflow flag is not correct"
    assert dut.overflow_flag.value == flags[1], "Overflow flag is not correct"
    assert dut.invalid_operation_flag.value == flags[2], "Invalid operation flag is not correct"


async def check_input_combo(dut, a, b, expected, flags, assert_message):
    dut.a.value = a
    dut.b.value = b

    await Timer(1, units="ns")
    assert_flags(dut, flags)
    assert dut.out.value == expected, assert_message


@cocotb.test()
async def test_normal_numbers(dut):
    await check_input_combo(dut, 0x40400000, 0x40800000, 0x41400000, (0, 0, 0), "3.0 * 4.0 != 12.0")
    await check_input_combo(dut, 0x410B3333, 0x3E99999A, 0x40270A3E, (0, 0, 0), "8.7 * 0.3 != 2.6100001")
    await check_input_combo(dut, 0x469C4600, 0x3DCCCCCD, 0x44FA099A, (0, 0, 0), "20003.0 * 0.1 != 2000.3")
    await check_input_combo(dut, 0x38D1B717, 0x3F6E147B, 0x38C308FE, (0, 0, 0), "0.0001 * 0.93 != 9.2999995E-5")


@cocotb.test()
async def test_denormalized_numbers(dut):
    await check_input_combo(dut, 0x00000001, 0x00000001, 0x00000000, (1, 0, 0), "1.1754944E-38 * 1.1754944E-38 != 0.0")


@cocotb.test()
async def test_infinity(dut):
    await check_input_combo(dut, 0x7F800000, 0x40400000, 0x7F800000, (0, 1, 0), "+Inf * 3.0 != +Inf")
    await check_input_combo(dut, 0x7F800000, 0x7F800000, 0x7F800000, (0, 1, 0), "+Inf * +Inf != +Inf")
    await check_input_combo(dut, 0xFF800000, 0x7F800000, 0xFF800000, (0, 1, 0), "-Inf * +Inf != -Inf")
    await check_input_combo(dut, 0xFF800000, 0xFF800000, 0x7F800000, (0, 1, 0), "-Inf * -Inf != +Inf")


@cocotb.test()
async def test_nan(dut):
    QNAN = 0xFFC00000
    SNAN = 0xFFA00000

    await check_input_combo(dut, QNAN, 0x40800000, QNAN, (0, 0, 1), "QNaN * 4.0 != QNaN")
    await check_input_combo(dut, SNAN, 0x40800000, QNAN, (0, 0, 1), "SNaN * 4.0 != QNaN")

@cocotb.test()
async def test_zero(dut):
    ZERO = 0x00000000
    QNAN = 0xFFC00000
    SNAN = 0xFFA00000

    await check_input_combo(dut, ZERO, 0x40400000, ZERO, (0, 0, 0), "0.0 * 3.0 != 0.0")
    await check_input_combo(dut, 0x42F00000, ZERO, ZERO, (0, 0, 0), "120.0 * 0.0 != 0.0")
    await check_input_combo(dut, QNAN, ZERO, QNAN, (0, 0, 1), "QNaN * 0.0 != QNaN")
    await check_input_combo(dut, SNAN, ZERO, QNAN, (0, 0, 1), "SNaN * 0.0 != QNaN")
