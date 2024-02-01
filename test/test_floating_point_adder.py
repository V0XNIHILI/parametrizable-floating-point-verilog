import pytest

from utils import run_module_test

@pytest.mark.parametrize("parameters", [{"EXPONENT_WIDTH": "8", "MANTISSA_WIDTH": "23", "ROUND_TO_NEAREST_TIES_TO_EVEN": "1"}, {"EXPONENT_WIDTH": "11", "MANTISSA_WIDTH": "52", "ROUND_TO_NEAREST_TIES_TO_EVEN": "1"}])
def test_floating_point_adder(parameters):
    return run_module_test("floating_point_adder",
                parameters=parameters,
                include_src_dir=True,
                # Dont fail on UNOPTFLAT due to the fact that Verilator thinks there is a loop in the design, while there is not.
                compile_args=['-Wno-UNOPTFLAT', '-Wno-WIDTHTRUNC'],
                create_vcd=True)


if __name__ == "__main__":
    test_floating_point_adder({"EXPONENT_WIDTH": "5", "MANTISSA_WIDTH": "10", "ROUND_TO_NEAREST_TIES_TO_EVEN": "1"})
