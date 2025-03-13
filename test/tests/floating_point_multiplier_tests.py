import cocotb
from cocotb.triggers import Timer

from common import is_IEEE_754_32_bit_float, is_IEEE_754_64_bit_float, is_IEEE_half_precision_float, get_bin_from_float_operation, assert_flags

TOTAL_RANDOM_FLOATS = 100*1000
POWERS = [-300, -12, -6, -3, 0, 6, 12, 24]


async def check_input_combo(dut, a, b, expected, flags, assert_message, check_both_ways=True):
    for (a_entry, b_entry) in [(a, b), (b, a)] if check_both_ways else [(a, b)]:
        dut.a.value = a_entry
        dut.b.value = b_entry

        await Timer(1, units="ns")
        assert_flags(dut, flags, assert_message)
        assert dut.out.value == expected, assert_message


@cocotb.test()
async def test_handcrafted_numbers(dut):
    if is_IEEE_754_32_bit_float(dut):
        await check_input_combo(dut, 0x40400000, 0x40800000, 0x41400000, (0, 0, 0), "3.0 * 4.0 != 12.0")
        await check_input_combo(dut, 0x410B3333, 0x3E99999A, 0x40270A3E, (0, 0, 0), "8.7 * 0.3 != 2.6100001")
        await check_input_combo(dut, 0x469C4600, 0x3DCCCCCD, 0x44FA099A, (0, 0, 0), "20003.0 * 0.1 != 2000.3")
        await check_input_combo(dut, 0x38D1B717, 0x3F6E147B, 0x38C308FE, (0, 0, 0), "0.0001 * 0.93 != 9.2999995E-5")
    else:
        assert True, "This test is not implemented for this floating point format"


@cocotb.test()
async def test_denormalized_numbers(dut):
    # Check smallest denormalized number
    
    await check_input_combo(dut, 1, 1, 0, (1, 0, 0), "Underflow should occur when multiplying two denormalized numbers")
    
    # Check largest denormalized number

    mant_bits = int(dut.MANTISSA_WIDTH)
    exp_bits = int(dut.EXPONENT_WIDTH)
    fp_width = mant_bits + exp_bits + 1

    denormalized = int("0" * (fp_width - mant_bits) + "1" * mant_bits, 2)

    await check_input_combo(dut, denormalized, denormalized, 0, (1, 0, 0), "Underflow should occur when multiplying two denormalized numbers")


@cocotb.test()
async def test_infinity(dut):
    if is_IEEE_754_32_bit_float(dut) or is_IEEE_754_64_bit_float(dut) or is_IEEE_half_precision_float(dut):
        if is_IEEE_754_32_bit_float(dut):
            PLUS_INF = 0x7F800000
            NEG_INF = 0xFF800000
            PLUS_THREE = 0x40400000
            VALUE_3241_COMMA_34 = 0x454A9571
        elif is_IEEE_half_precision_float(dut):
            PLUS_INF = 0x7C00
            NEG_INF = 0xFC00
            PLUS_THREE = 0x4200
            VALUE_3241_COMMA_34 = 0x6A55
        else:
            PLUS_INF = 0x7FF0000000000000
            NEG_INF = 0xFFF0000000000000
            PLUS_THREE = 0x4008000000000000
            VALUE_3241_COMMA_34 = 0x40A952AE147AE148

        await check_input_combo(dut, PLUS_INF, PLUS_THREE, PLUS_INF, (0, 1, 0), "+Inf * 3.0 != +Inf")
        await check_input_combo(dut, NEG_INF, VALUE_3241_COMMA_34, NEG_INF, (0, 1, 0), "-Inf * 3241.34 != -Inf")
        await check_input_combo(dut, PLUS_INF, PLUS_INF, PLUS_INF, (0, 1, 0), "+Inf * +Inf != +Inf")
        await check_input_combo(dut, NEG_INF, PLUS_INF, NEG_INF, (0, 1, 0), "-Inf * +Inf != -Inf")
        await check_input_combo(dut, NEG_INF, NEG_INF, PLUS_INF, (0, 1, 0), "-Inf * -Inf != +Inf")
    else:
        assert False, "This test is not implemented for this floating point format"


@cocotb.test()
async def test_nan(dut):
    if is_IEEE_754_32_bit_float(dut) or is_IEEE_754_64_bit_float(dut) or is_IEEE_half_precision_float(dut):
        if is_IEEE_754_32_bit_float(dut):
            QNAN = 0xFFC00000
            SNAN = 0xFFA00000
            PLUS_THREE = 0x40400000
        elif is_IEEE_half_precision_float(dut):
            QNAN = int("1" + "1" * 5 + "1" + "0" * 9, 2)
            SNAN = int("1" + "1" * 5 + "0" + "0" * 9, 2)
            PLUS_THREE = 0x4200
        else:
            QNAN = int("1" + "1" * 11 + "1" + "0" * 51, 2)
            SNAN = int("1" + "1" * 11 + "0" + "0" * 51, 2)
            PLUS_THREE = 0x4008000000000000

        await check_input_combo(dut, QNAN, PLUS_THREE, QNAN, (0, 0, 1), "QNaN * 3.0 != QNaN")
        await check_input_combo(dut, SNAN, PLUS_THREE, QNAN, (0, 0, 1), "SNaN * 3.0 != QNaN")
    else:
        assert False, "This test is not implemented for this floating point format"

@cocotb.test()
async def test_zero(dut):
    if is_IEEE_754_32_bit_float(dut) or is_IEEE_754_64_bit_float(dut) or is_IEEE_half_precision_float(dut):
        ZERO = 0x00000000

        if is_IEEE_754_32_bit_float(dut):
            QNAN = 0xFFC00000
            SNAN = 0xFFA00000
            PLUS_THREE = 0x40400000
            PLUS_120 = 0x42F00000
        elif is_IEEE_half_precision_float(dut):
            QNAN = int("1" + "1" * 5 + "1" + "0" * 9, 2)
            SNAN = int("1" + "1" * 5 + "0" + "0" * 9, 2)
            PLUS_THREE = 0x4200
            PLUS_120 = 0x5780
        else:
            QNAN = int("1" + "1" * 11 + "1" + "0" * 51, 2)
            SNAN = int("1" + "1" * 11 + "0" + "0" * 51, 2)
            PLUS_THREE = 0x4008000000000000
            PLUS_120 = 0x405E000000000000

        await check_input_combo(dut, ZERO, PLUS_THREE, ZERO, (0, 0, 0), "0.0 * 3.0 != 0.0")
        await check_input_combo(dut, PLUS_120, ZERO, ZERO, (0, 0, 0), "120.0 * 0.0 != 0.0")
        await check_input_combo(dut, QNAN, ZERO, QNAN, (0, 0, 1), "QNaN * 0.0 != QNaN")
        await check_input_combo(dut, SNAN, ZERO, QNAN, (0, 0, 1), "SNaN * 0.0 != QNaN")
    else:
        assert False, "This test is not implemented for this floating point format"


@cocotb.test()
async def test_random_floats(dut):
    import random
    import numpy as np

    np.random.seed(0)
    random.seed(0)

    exp_bits = int(dut.EXPONENT_WIDTH)
    mant_bits = int(dut.MANTISSA_WIDTH)

    for power in POWERS:
        scale_ub = 10 ** power
        scale_lb = 10 ** (power - 1)

        for _ in range(TOTAL_RANDOM_FLOATS):
            a = random.uniform(scale_lb, scale_ub)
            b = random.uniform(scale_lb, scale_ub)

            # get two random booleans
            negative_a = random.choice([True, False])
            negative_b = random.choice([True, False])

            if negative_a:
                a = -a

            if negative_b:
                a = -b

            if is_IEEE_754_32_bit_float(dut) or is_IEEE_754_64_bit_float(dut) or is_IEEE_half_precision_float(dut):
                width = exp_bits + mant_bits + 1
                (a_str, b_str, result_str), result, flags = get_bin_from_float_operation(a, b, '*', width, exp_bits, mant_bits)
            else:
                assert False, f"This test is not implemented for this floating point format with exponent width {exp_bits} and mantissa width {mant_bits}"

            a_int = int(a_str, 2)
            b_int = int(b_str, 2)
            result_int = int(result_str, 2)

            await check_input_combo(dut, a_int,b_int, result_int, flags, f"{a} * {b} != {result}")
