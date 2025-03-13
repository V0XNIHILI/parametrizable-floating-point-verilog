import numpy as np


def is_IEEE_754_32_bit_float(dut):
    if int(dut.EXPONENT_WIDTH) == 8 and int(dut.MANTISSA_WIDTH) == 23 and int(dut.ROUND_TO_NEAREST_TIES_TO_EVEN) == 1:
        return True
    
    return False


def is_IEEE_754_64_bit_float(dut):
    if int(dut.EXPONENT_WIDTH) == 11 and int(dut.MANTISSA_WIDTH) == 52 and int(dut.ROUND_TO_NEAREST_TIES_TO_EVEN) == 1:
        return True
    
    return False


def is_IEEE_half_precision_float(dut):
    if int(dut.EXPONENT_WIDTH) == 5 and int(dut.MANTISSA_WIDTH) == 10 and int(dut.ROUND_TO_NEAREST_TIES_TO_EVEN) == 1:
        return True
    
    return False


def get_bin_from_float(value, bits, flt, integer):
    return f'{{:0{bits}b}}'.format(flt(value).view(integer).item())


def smallest_float_value_with_denormals(exponent_bits: int, mantissa_bits: int) -> float:
    return 1/(2**mantissa_bits)*2**-(2**(exponent_bits-1)-2)


def get_bin_from_float_operation(a, b, op, bits, exponent_bits, mantissa_bits):
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
    
    a_bin = get_bin_from_float(a, bits, flt, integer)
    b_bin = get_bin_from_float(b, bits, flt, integer)
    result_bin = get_bin_from_float(result, bits, flt, integer)
    
    smallest_float = smallest_float_value_with_denormals(exponent_bits, mantissa_bits)

    underflow_flag = False
    overflow_flag = False
    invalid_operation_flag = False

    if result == np.inf or result == -np.inf:
        overflow_flag = True
    elif result == np.nan:
        invalid_operation_flag = True
    elif op == "*" and (a != 0.0 and b != 0 and result == 0):
        underflow_flag = True
    elif abs(result) <= smallest_float:
        # TODO: this does not work for FP64, as Python uses 64-bit floats (on almost all systems)...

        underflow_flag = True

        if op == "*" and underflow_flag:
            sign = int(a_bin[0]) ^ int(b_bin[0])
            result_bin = f"{sign}{'0' * (bits - 1)}"

    return (a_bin, b_bin, result_bin), result, (underflow_flag, overflow_flag, invalid_operation_flag)


def assert_flags(dut, flags, message):
    assert dut.underflow_flag.value == flags[0], f"Underflow flag is not correct for {message}"
    assert dut.overflow_flag.value == flags[1], f"Overflow flag is not correct for {message}"
    assert dut.invalid_operation_flag.value == flags[2], f"Invalid operation flag is not correct for {message}"


print(smallest_float_value_with_denormals(8, 23))