from pathlib import Path

import pytest

from cocotb_test.simulator import run

BASE_WIDTH = 8
WIDTHS = [3, 4, 6, BASE_WIDTH, 16]


@pytest.mark.parametrize("parameters", [{"WIDTH": w} for w in WIDTHS])
def test_leading_one_detector(parameters):
    module_name = "leading_one_detector"

    file_dir = Path(__file__).resolve().parent
    source_dir = str(file_dir / ".." / "src")

    run(
        simulator="verilator",
        verilog_sources=[f"{source_dir}/{module_name}.v"],
        toplevel=module_name,
        module=f"tests.{module_name}_tests",
        parameters=parameters,
        compile_args=[''] #  '--x-assign unique', '--x-initial unique'
    )


if __name__ == "__main__":
    test_leading_one_detector({"WIDTH": BASE_WIDTH})
