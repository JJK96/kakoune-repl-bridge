import pexpect
import pexpect.replwrap
import sys

input = sys.argv[1]
output = sys.argv[2]
langfile = sys.argv[3]

with open(langfile, 'r') as config:
    lines = [x[:-1] for x in config.readlines()]

p = pexpect.replwrap.REPLWrapper(lines[0], lines[1], lines[2])
if len(sys.argv) > 3:
    extra_init_cmd = sys.argv[3]
    p.run_command(extra_init_cmd)

while True:
    with open(input, 'r') as f:
        c = f.read()
        if c.startswith("!exit"):
            exit()
        try:
            out = open(output, 'w')
            out.write(p.run_command(c).replace('\r', ''))
        finally:
            out.close()
