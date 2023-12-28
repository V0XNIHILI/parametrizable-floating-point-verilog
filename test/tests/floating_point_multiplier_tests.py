import cocotb
from cocotb.triggers import Timer


TOTAL_RANDOM_FLOATS = 1000
POWERS = [-300, -12, -6, -3, 0, 6, 12, 24]


def assert_flags(dut, flags):
    assert dut.underflow_flag.value == flags[0], "Underflow flag is not correct"
    assert dut.overflow_flag.value == flags[1], "Overflow flag is not correct"
    assert dut.invalid_operation_flag.value == flags[2], "Invalid operation flag is not correct"


async def check_input_combo(dut, a, b, expected, flags, assert_message, check_both_ways=True):
    for (a_entry, b_entry) in [(a, b), (b, a)] if check_both_ways else [(a, b)]:
        dut.a.value = a_entry
        dut.b.value = b_entry

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
    PLUS_INF = 0x7F800000
    NEG_INF = 0xFF800000

    await check_input_combo(dut, PLUS_INF, 0x40400000, PLUS_INF, (0, 1, 0), "+Inf * 3.0 != +Inf")
    await check_input_combo(dut, PLUS_INF, PLUS_INF, PLUS_INF, (0, 1, 0), "+Inf * +Inf != +Inf")
    await check_input_combo(dut, NEG_INF, PLUS_INF, NEG_INF, (0, 1, 0), "-Inf * +Inf != -Inf")
    await check_input_combo(dut, NEG_INF, NEG_INF, PLUS_INF, (0, 1, 0), "-Inf * -Inf != +Inf")


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

@cocotb.test()
async def test_random_floats(dut):
    import random
    import numpy as np

    for power in POWERS:
        scale = 10 ** power

        for _ in range(TOTAL_RANDOM_FLOATS):
            underflow_flag = 0
            overflow_flag = 0
            invalid_operation_flag = 0

            a = random.uniform(-scale, scale)
            b = random.uniform(-scale, scale)

            result = np.float32(a) * np.float32(b)

            a_str = '{:032b}'.format(np.float32(a).view(np.uint32).item())
            b_str = '{:032b}'.format(np.float32(b).view(np.uint32).item())
            result_str = '{:032b}'.format(np.float32(result).view(np.uint32).item())

            a_int = int(a_str, 2)
            b_int = int(b_str, 2)
            result_int = int(result_str, 2)

            if result == np.inf or result == -np.inf:
                overflow_flag = True
            elif result == np.nan:
                invalid_operation_flag = True
            elif a != 0.0 and b != 0 and result == 0:
                underflow_flag = True

            flags = (underflow_flag, overflow_flag, invalid_operation_flag)

            await check_input_combo(dut, a_int,b_int, result_int, flags, f"{a} * {b} != {result}")
