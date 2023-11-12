import serial
import time
import sys
import numpy as np
from matplotlib import pyplot as plt
from struct import *

if len(sys.argv)<2 :
	print("Not enough arguments, need serial port name param")
port_name = sys.argv[1]
print(port_name)

port = serial.Serial()
port.baudrate=6000000
port.port=port_name
port.bytesize=8
port.parity='N'
port.stopbits=1
port.open()

#serial data to ADC data
def conv( sd ):
	i=0
	while sd[i]&0x80 == 0 :
		i=i+1
	lc=[]
	rc=[]
	while i<(len(sd)-5) :
		b0 = sd[i+1] | ((sd[i+0]&1)<<7)
		b1 = sd[i+2] | ((sd[i+0]&2)<<6)
		a=bytearray([b1,b0])
		left,*rest = unpack('>h',a)
		b0 = sd[i+3] | ((sd[i+0]&4)<<5)
		b1 = sd[i+4] | ((sd[i+0]&8)<<4)
		a=bytearray([b1,b0])
		right,*rest = unpack('>h',a)
		lc.append(left)
		rc.append(right)
		i=i+5
	return [lc,rc]

def f(adc_data):
	sync_idx = 0
	for i in range(1024) :
		if adc_data[i]<0 and adc_data[i+10]>=0 :
			sync_idx = i
			break
	y=[]
	for i in range(1024) :
		y.append(adc_data[sync_idx+i])
	return y

x = np.arange(0, 1024)

plt.rcParams["figure.figsize"] = [7.50, 3.50]
plt.rcParams["figure.autolayout"] = True
plt.ion()
fig,ax = plt.subplots(2,1)
ax[0].set_xlabel('Idx')
ax[0].set_ylabel('Left Channel')
ax[0].set_ylim([-33000, +33000])
line0, = ax[0].plot(x, f(x), color='red') # Returns a tuple of line objects, thus the comma
ax[1].set_xlabel('Idx')
ax[1].set_ylabel('Right Channel')
ax[1].set_ylim([-33000, +33000])
line1, = ax[1].plot(x, f(x), color='red') # Returns a tuple of line objects, thus the comma
while 1 :
	port.flushInput()
	serial_data = port.read( 1024*10 )
	data = conv(serial_data)
	CL=data[0]
	CR=data[1]
	line0.set_ydata(f(CL))
	line1.set_ydata(f(CR))
	fig.canvas.draw()
	fig.canvas.flush_events()
	#time.sleep(1)

port.close()
