spawn <SPIKE> -d -l --isa=rv32imc --pc=0x80000000 -m0x80000000:65536 <ELF>
expect "*:"
send -- "run 200000\n"
expect "*:"
send -- "quit\n"
expect eof
