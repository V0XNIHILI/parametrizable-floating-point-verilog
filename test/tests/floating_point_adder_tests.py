import cocotb
from cocotb.triggers import Timer

from common import is_IEEE_754_32_bit_float, is_IEEE_754_64_bit_float, assert_flags


# TODO: test rounding or not
TOTAL_RANDOM_FLOATS = 10000
POWERS = [-300, -12, -6, -3, 0, 6, 12, 24]


async def check_input_combo(dut, a, b, subtract, expected, flags, assert_message, check_both_ways=True):
    check_both_ways = False
    for (a_entry, b_entry) in [(a, b), (b, a)] if check_both_ways and not subtract else [(a, b)]:
        dut.a.value = a_entry
        dut.b.value = b_entry
        dut.subtract.value = subtract

        await Timer(1, units="ns")
        assert_flags(dut, flags)
        assert dut.out.value == expected, assert_message


@cocotb.test()
async def test_normal_numbers(dut):
    if is_IEEE_754_32_bit_float(dut):
        await check_input_combo(dut, 0x40400000, 0x40800000, False, 0x40E00000, (0, 0, 0), "3.0 + 4.0 != 7.0")
        await check_input_combo(dut, 0x410B3333, 0x3E99999A, False, 0x41100000, (0, 0, 0), "8.7 + 0.3 != 9.0")
        await check_input_combo(dut, 0x469C4600, 0x3DCCCCCD, False, 0x469C4633, (0, 0, 0), "20003.0 + 0.1 != 20003.1")
        await check_input_combo(dut, 0x38D1B717, 0x3F6E147B, False, 0x3F6E1B09, (0, 0, 0), "0.0001 + 0.93 != 0.9301")
        await check_input_combo(dut, 0x3DFCDE47, 0xBF38A9F3, False, 0xBF190E2A, (0, 0, 0), "0.0001 + 0.93 != 0.9301")
        await check_input_combo(dut, 0xBF656347, 0xBF0E01E9, False, 0xBFB9B298, (0, 0, 0), "-0.8960460830977122 + -0.554716643116743 != -1.4507627487182617")
    elif is_IEEE_754_64_bit_float(dut):
        assert True, "This test is not implemented for 64-bit IEEE 754 floats"
    else:
        assert False, "This test is not implemented for this floating point format"


@cocotb.test()
async def test_infinity(dut):
    if is_IEEE_754_32_bit_float(dut):
        PLUS_INF = 0x7F800000
        NEG_INF = 0xFF800000
        QNAN = 0xFFC00000

        await check_input_combo(dut, PLUS_INF, 0x40400000, False, PLUS_INF, (0, 1, 0), "+Inf + 3.0 != +Inf")
        await check_input_combo(dut, PLUS_INF, PLUS_INF, False, PLUS_INF, (0, 1, 0), "+Inf + +Inf != +Inf")
        await check_input_combo(dut, NEG_INF, PLUS_INF, False, QNAN, (0, 0, 1), "-Inf + +Inf != QNaN")
        await check_input_combo(dut, PLUS_INF, NEG_INF, True, QNAN, (0, 0, 1), "+Inf - +Inf != QNaN")
        await check_input_combo(dut, NEG_INF, NEG_INF, False, NEG_INF, (0, 1, 0), "-Inf + -Inf = -Inf")
    elif is_IEEE_754_64_bit_float(dut):
        assert True, "This test is not implemented for 64-bit IEEE 754 floats"
    else:
        assert False, "This test is not implemented for this floating point format"



@cocotb.test()
async def test_zero(dut):
    if is_IEEE_754_32_bit_float(dut):
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
    elif is_IEEE_754_64_bit_float(dut):
        assert True, "This test is not implemented for 64-bit IEEE 754 floats"
    else:
        assert False, "This test is not implemented for this floating point format"


@cocotb.test()
async def test_random_floats(dut):
    import random
    import numpy as np

    for power in POWERS:
        scale = 10 ** power

        for subtract in [False, True]:
            for _ in range(TOTAL_RANDOM_FLOATS):
                underflow_flag = 0
                overflow_flag = 0
                invalid_operation_flag = 0

                a = random.uniform(-scale, scale)
                b = random.uniform(-scale, scale)

                skip_test = False

                if is_IEEE_754_32_bit_float(dut):
                    if subtract:
                        result = np.float32(a) - np.float32(b)
                    else:
                        result = np.float32(a) + np.float32(b)

                    a_str = '{:032b}'.format(np.float32(a).view(np.uint32).item())
                    b_str = '{:032b}'.format(np.float32(b).view(np.uint32).item())
                    result_str = '{:032b}'.format(np.float32(result).view(np.uint32).item())
                elif is_IEEE_754_64_bit_float(dut):
                    if subtract:
                        result = np.float64(a) - np.float64(b)
                    else:
                        result = np.float64(a) + np.float64(b)

                    a_str = '{:064b}'.format(np.float64(a).view(np.uint64).item())
                    b_str = '{:064b}'.format(np.float64(b).view(np.uint64).item())
                    result_str = '{:064b}'.format(np.float64(result).view(np.uint64).item())
                else:
                    skip_test = True
                    assert False, "This test is not implemented for this floating point format"

                if not skip_test:
                    a_int = int(a_str, 2)
                    b_int = int(b_str, 2)
                    result_int = int(result_str, 2)

                    if result == np.inf or result == -np.inf:
                        overflow_flag = True
                    elif result == np.nan:
                        invalid_operation_flag = True
                    # TODO: add underflow flag test

                    flags = (underflow_flag, overflow_flag, invalid_operation_flag)

                    await check_input_combo(dut, a_int, b_int, subtract, result_int, flags, f"{a} {'-' if subtract else '+'} {b} != {result}")
                else:
                    break
