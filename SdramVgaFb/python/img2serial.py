import serial
import time
import numpy as np
import sys
from PIL import Image

if len(sys.argv)<5 :
	print("Need 4 arguments: COM-port name, jpeg/bitmap filename, display X and display Y")
	sys.exit()

port_name = sys.argv[1]
img_name = sys.argv[2]
CoordX = int(sys.argv[3])
CoordY = int(sys.argv[4])

im = Image.open(img_name)
iwidth, iheight = im.size
print(iwidth,iheight)

# Convert Pillow image to NumPy array
img_array = np.array(im, dtype=np.uint8)

#convert image into array of draw commands
rgb565=[]
y=0
while y<iheight :
	#line of hi-color 5-6-5 pixels need bytes:
	ba=bytearray([0xFF]*iwidth*2)
	x=0
	while x<iwidth :
		pixel0 = img_array[y][x+0]
		r0 = pixel0[0]
		g0 = pixel0[1]
		b0 = pixel0[2]
		ba[x*2+0] = ((b0>>3)&0x1F) | ((g0<<3)&0xE0)
		ba[x*2+1] = (r0&0xF8) | ((g0>>5)&0x07)
		x=x+1
		pixel1 = img_array[y][x]
		r1 = pixel1[0]
		g1 = pixel1[1]
		b1 = pixel1[2]
		ba[x*2+0] = ((b1>>3)&0x1F) | ((g1<<3)&0xE0)
		ba[x*2+1] = (r1&0xF8) | ((g1>>5)&0x07)
		x=x+1
	rgb565.append(ba)
	y=y+1

#k=0
#while k<32 :
#	print(k,rgb565[0][k])
#	k=k+1

port = serial.Serial()
port.baudrate=3000000
port.port=port_name
port.bytesize=8
port.parity='N'
port.stopbits=1
#port.write_timeout=0;
port.open()
print(port.name)

X=CoordX
Y=CoordY
adr=Y*1024+int(X/2)
hdr = bytearray([0x10,0x00,0x55,0xAA,0x10,0x05,0x00,0x00])
numwrites = int(iwidth/2)
hdr[0]=numwrites&0xFF
hdr[1]=int((numwrites/256))&0xFF
	
y=0
while y<iheight :
	hdr[4]=adr&0xFF
	hdr[5]=int(adr>>8 )&0xFF
	hdr[6]=int(adr>>16)&0xFF
	adr=adr+1024
	port.write( hdr )
	port.write( rgb565[y] )
	y=y+1

port.close()
