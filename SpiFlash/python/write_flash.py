import serial
import time
import sys

#arguments: SerialPortName, FileName, Address
if len(sys.argv)<4 :
	print("Not enough arguments")
	
port_name = sys.argv[1]
file_name = sys.argv[2]
flash_addr = int(sys.argv[3],16)

print("Write ", file_name, " to ", flash_addr)

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

def wait_not_busy():
	sr0 = 1
	while sr0 & 1 :
		r = read_spi_flash_sr0()
		sr0=r[1]

def spi_flash_sector_erase( addr ) :
	a0 = addr & 0xFF
	a1 = (addr>>8) & 0xFF
	a2 = (addr>>16) & 0xFF
	cmd20 = bytearray([0x20,a2,a1,a0])
	spi_flash_rw(cmd20)
	wait_not_busy()

def write_buffer(ba256,addr) :
	print("Write enable and read status")
	if ( addr & 0xFFF ) == 0 :
		#erase on sector 4K boundary
		spi_flash_write_enable()
		#read_spi_flash_sr0()
		print("Erase and read status")
		spi_flash_sector_erase( addr )

	print("Write enable and read status")
	spi_flash_write_enable()
	read_spi_flash_sr0()

	print("Write")
	ba=bytearray(1+3+256)
	ba[0]=0x02
	ba[1]=(addr>>16) & 0xFF
	ba[2]=(addr>>8) & 0xFF
	ba[3]=addr & 0xFF
	i=0
	while i<256 :
		ba[4+i]=ba256[i]
		i=i+1
	spi_flash_rw(ba)
	wait_not_busy()
	
def disable_quad_mode():
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

spi_flash_power_up()
spi_flash_read_jedec_id()
disable_quad_mode()

with open(file_name, mode="rb") as rdfile:
	wrbytes = rdfile.read()
	ba = bytearray(wrbytes)
	file_len = len(ba)
	print("File length",file_len)
	written = 0
	while written<file_len:
		ba256 = bytearray(256)
		i=0
		while (written+i)<file_len and i<256:
			ba256[i] = ba[written+i]
			i=i+1
		write_buffer(ba256,flash_addr)
		flash_addr=flash_addr+256
		written=written+256

port.close()
