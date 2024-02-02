from typing import Optional

from pathlib import Path

from cocotb_test.simulator import run

def run_module_test(module_name: str, extension: str = "v", file_name: Optional[str] = None, parameters : Optional[dict] = None, include_src_dir: bool = False, use_basic_compile_args: bool = True, compile_args: Optional[list] = None, create_vcd: bool = False, simulator: str = "verilator"):
    file_dir = Path(__file__).resolve().parent
    source_dir = str(file_dir / ".." / "src")

    # Ignore WIDTHEXPAND warnings: https://verilator.org/guide/latest/warnings.html#cmdoption-arg-WIDTHEXPAND
    # This is when you use 4 bits but you would need 5 bits, but this is in 99.99% of the cases as intended
    basic_compile_args = ['-Wno-WIDTHEXPAND'] if use_basic_compile_args else []
    extra_args = []

    if include_src_dir:
        if simulator == "verilator":
            basic_compile_args.insert(0, f"+incdir+{source_dir}")
        else:
            raise ValueError(f"Include source directory is not supported for this ({simulator}) simulator")
        
    if create_vcd:
        if simulator == "verilator":
            extra_args.append("--trace")
        else:
            raise ValueError(f"Create VCD is not supported for this ({simulator}) simulator")
    
    compile_args = list(set(basic_compile_args + (compile_args or [])))
        
    if file_name is None:
        file_name = f"{module_name}.{extension}"

    return run(
        simulator=simulator,
        verilog_sources=[f"{source_dir}/{file_name}"],
        toplevel=module_name,
        module=f"tests.{module_name}_tests",
        parameters=parameters,
        compile_args=compile_args, #  '--x-assign unique', '--x-initial unique'
        extra_args=extra_args
    )
