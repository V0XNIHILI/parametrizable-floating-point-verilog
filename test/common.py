import numpy as np


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


def get_bin_from_float(value, bits, flt, integer):
    return f'{{:0{bits}b}}'.format(flt(value).view(integer).item())


def get_bin_from_float_operation(a, b, op, bits):
    if bits == 32:
        flt = np.float32
        integer = np.uint32
    elif bits == 64:
        flt = np.float64
        integer = np.uint64
    elif bits == 16:
        flt = np.float16
        integer = np.uint16
    else:
        raise ValueError("Bits must be 32, 64, or 16")
    
    if op == '+':
        result = flt(a) + flt(b)
    elif op == '-':
        result = flt(a) - flt(b)
    elif op == '*':
        result = flt(a) * flt(b)
    else:
        raise ValueError("Operation must be +, -, or *")

    return ([get_bin_from_float(value, bits, flt, integer) for value in [a, b, result]], result)


def assert_flags(dut, flags, message):
    assert dut.underflow_flag.value == flags[0], f"Underflow flag is not correct for {message}"
    assert dut.overflow_flag.value == flags[1], f"Overflow flag is not correct for {message}"
    assert dut.invalid_operation_flag.value == flags[2], f"Invalid operation flag is not correct for {message}"
