from pathlib import Path

import pytest

from cocotb_test.simulator import run


@pytest.mark.parametrize("parameters", [{"EXPONENT_WIDTH": "8", "MANTISSA_WIDTH": "23", "ROUND_TO_NEAREST": "1"}, {"EXPONENT_WIDTH": "11", "MANTISSA_WIDTH": "52", "ROUND_TO_NEAREST": "1"}])
def test_floating_point_multiplier(parameters):
    module_name = "floating_point_multiplier"

    file_dir = Path(__file__).resolve().parent
    source_dir = str(file_dir / ".." / "src")

    run(
        simulator="verilator",
        verilog_sources=[f"{source_dir}/{module_name}.v"],
        toplevel=module_name,
        module=f"tests.{module_name}_tests",
        parameters=parameters,
        # Dont fail on UNOPTFLAT due to the fact that Verilator thinks there is a loop in the design, while there is not.
        compile_args=[f"+incdir+{source_dir}", '-Wno-WIDTHEXPAND', '-Wno-UNOPTFLAT'] #  '--x-assign unique', '--x-initial unique'
    )


if __name__ == "__main__":
    test_floating_point_multiplier({"EXPONENT_WIDTH": "11", "MANTISSA_WIDTH": "52", "ROUND_TO_NEAREST": "1"})
