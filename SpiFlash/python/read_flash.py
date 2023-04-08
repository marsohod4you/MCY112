import serial
import time
import sys

#arguments: SerialPortName, FileName, Address, Length
if len(sys.argv)<5 :
	print("Not enough arguments")
	
port_name = sys.argv[1]
file_name = sys.argv[2]
flash_addr = int(sys.argv[3],16)
file_len = int(sys.argv[4])

print("Read ", file_name, " length ", file_len, " from ", flash_addr)

port = serial.Serial()
port.baudrate=6000000
port.port=port_name
port.bytesize=8
port.parity='N'
port.stopbits=1
#port.write_timeout=0;
port.open()
print(port.name)

def reverse_byte_bits(n, no_of_bits):
    result = 0
    for i in range(no_of_bits):
        result <<= 1
        result |= n & 1
        n >>= 1
    return result

def reverse_bits_ba(ba):
    for i in range( len(ba)):
        ba[i] = reverse_byte_bits(ba[i],8)

def print_ba(s,ba):
	rs = "".join("{:02x}".format(x) for x in ba)
	print(s,rs)

def spi_flash_rw( ba ) :
	len_ba = len(ba)
	if len_ba<10 :
		print_ba( "> ",ba )
	reverse_bits_ba( ba )
	port.write( ba )
	#time.sleep(0.1)
	r = port.read( len_ba+1 )
	if len_ba<10 :
		print_ba( "< ",r )
	return r[0:len_ba]

def spi_flash_power_up() :
	cmdAB = bytearray([0xAB,0x00,0x00,0x00,0x00])
	spi_flash_rw(cmdAB)

def spi_flash_read_jedec_id() :
	cmd9F = bytearray([0x9F,0x00,0x00,0x00])
	spi_flash_rw(cmd9F)
	
def read_spi_flash_sr0() :
	cmd05 = bytearray([0x05,0x00])
	r = spi_flash_rw(cmd05)
	return r

def read_spi_flash_sr1() :
	cmd35 = bytearray([0x35,0x00])
	r = spi_flash_rw(cmd35)
	return r
	
def spi_flash_write_enable() :
	cmd06 = bytearray([0x06])
	spi_flash_rw(cmd06)

def spi_flash_sector_erase( addr ) :
	a0 = addr & 0xFF
	a1 = (addr>>8) & 0xFF
	a2 = (addr>>16) & 0xFF
	cmd20 = bytearray([0x20,a2,a1,a0])
	spi_flash_rw(cmd20)

print("Power Up")
spi_flash_power_up()
spi_flash_read_jedec_id()

print("Status")
sr0 = read_spi_flash_sr0()
sr1 = read_spi_flash_sr1()

#volatile SR write enable
ba=bytearray(1)
ba[0]=0x50
spi_flash_rw(ba)

#disable Quad mode
ba=bytearray(3)
ba[0]=0x01
ba[1]=sr0[1]
ba[2]=sr1[1] & 0xFD #suppress 2nd bit Quad Enable
spi_flash_rw(ba)

with open(file_name, "wb") as wrfile:
	got=0
	while got<file_len :
		print("Read page at ",got)
		ba=bytearray(1+3+256)
		ba[0]=0x03
		ba[1]= (flash_addr>>16) & 0xFF
		ba[2]= (flash_addr>>8) & 0xFF
		ba[3]=  flash_addr & 0xFF
		i=0
		while i<256 :
			ba[3+i]=0
			i=i+1
		r = spi_flash_rw(ba)
		E=file_len-got
		if E<256 :
			wrbytes = bytes(r[4:E+4])
		else :
			wrbytes = bytes(r[4:])
		wrfile.write(wrbytes)
		got=got+256
		flash_addr=flash_addr+256

port.close()
