files=$(find "../" -type f -name "*.v")
files+=$(find "../" -type f -name "*.sv")

for file in $files; do
    echo "Formatting $file"
    verible-verilog-format --flagfile=../.verible-format-flags $file
done
