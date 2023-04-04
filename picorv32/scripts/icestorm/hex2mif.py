'''
This script helps to convert hex instructions to Quartus .mif files.
To run it, use "python hex2mif.py input.txt output.mif"
For input file, assuming you are using Mars as assember,
you need to export the binary instruction as hexadecimal text file.
But for any kind of input files, it should work fine as long as
it uses the following format:
DEADBEEF
BAADF00D
'''

import sys

def read(f_in):
    with open(f_in) as f:
        return [int(i, 16) for i in f if len(i) != 0]


def write(f_out, data, width=32, depth=2048):
    if len(data) > depth:
        print('Data larger than memory size, abort.')
    else:
        buf = 'WIDTH={:d};\nDEPTH={:d};\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n'.format(width, depth)
        l_index = str(len('{:x}'.format(depth)))
        l_data = str(int(width / 4))
        s = '\t{:0' + l_index + 'X} : {:0' + l_data + 'X};\n'
        for i, j in enumerate(data):
            buf += s.format(i, j)
        if len(buf) == depth - 1:
            buf += s.format(depth - 1, 0)
        elif len(buf) < depth - 1:
            buf += ('\t[{:0' + l_index + 'X}..{:0' + l_index + 'X}] : {:0' + l_data + 'X};\n').format(len(data), depth - 1, 0)
        buf += 'END;\n'
        with open(f_out, 'w') as f:
            f.write(buf)


def convert(f_in, f_out):
    write(f_out, read(f_in))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print ('Usage: hex2mif input.txt output.mif')
    else:
        in_ = sys.argv[1]
        out_ = sys.argv[2]
        if not out_.endswith('.mif'):
            print('Output file must be .mif file')
        else:
            convert(in_, out_)
            print('Converted ' + in_ + ' to ' + out_ + '.')
			