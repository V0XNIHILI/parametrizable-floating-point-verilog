import math

import cocotb
from cocotb.triggers import Timer


async def check_input_combo(dut, in_value, expected):
    dut.value.value = in_value

    await Timer(1, units="ns")
    
    if expected[0] is not None:
        assert dut.position.value == expected[0], f"Leading one position is not correct for {bin(in_value)}!"

    assert dut.has_leading_one.value == expected[1], f"Has leading one is not correct for {bin(in_value)}!"


@cocotb.test()
async def test_single_one(dut):
    WIDTH = int(dut.WIDTH)

    max_width = WIDTH

    for width in range(max_width):
        await check_input_combo(dut, 1 << width, (width, True))


@cocotb.test()
async def test_all_numbers(dut):
    WIDTH = int(dut.WIDTH)

    # if WIDTH < 8:
    max_entry = 1 << WIDTH

    for entry in range(max_entry):
        non_zero_entry = entry != 0
        expected_position =  math.floor(math.log(entry, 2)) if non_zero_entry else None 

        await check_input_combo(dut, entry, (expected_position, non_zero_entry))


@cocotb.test()
async def test_input_without_one(dut):
    await check_input_combo(dut, 0, (None, False))
