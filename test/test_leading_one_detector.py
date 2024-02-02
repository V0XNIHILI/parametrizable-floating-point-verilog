import pytest

from utils import run_module_test

BASE_WIDTH = 8
WIDTHS = [3, 4, 6, BASE_WIDTH, 16]


@pytest.mark.parametrize("parameters", [{"WIDTH": w} for w in WIDTHS])
def test_leading_one_detector(parameters):
    run_module_test("leading_one_detector",
                           parameters=parameters,
                           use_basic_compile_args=False)


if __name__ == "__main__":
    test_leading_one_detector({"WIDTH": BASE_WIDTH})
