def is_IEEE_754_32_bit_float(dut):
    if int(dut.EXPONENT_WIDTH) == 8 and int(dut.MANTISSA_WIDTH) == 23 and int(dut.ROUND_TO_NEAREST) == 1:
        return True
    
    return False


def is_IEEE_754_64_bit_float(dut):
    if int(dut.EXPONENT_WIDTH) == 11 and int(dut.MANTISSA_WIDTH) == 52 and int(dut.ROUND_TO_NEAREST) == 1:
        return True
    
    return False


def is_16_bit_float(dut):
    if int(dut.EXPONENT_WIDTH) == 5 and int(dut.MANTISSA_WIDTH) == 10 and int(dut.ROUND_TO_NEAREST) == 1:
        return True
    
    return False


def assert_flags(dut, flags):
    assert dut.underflow_flag.value == flags[0], "Underflow flag is not correct"
    assert dut.overflow_flag.value == flags[1], "Overflow flag is not correct"
    assert dut.invalid_operation_flag.value == flags[2], "Invalid operation flag is not correct"
