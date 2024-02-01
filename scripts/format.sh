files=$(find "../src" -type f \( -name "*.v" -o -name "*.vh" -o -name "*.sv" -o -name "*.svh" \))

for file in $files; do
    echo "Formatting $file"
    verible-verilog-format --flagfile=../.verible-format-flags --inplace $file
done
