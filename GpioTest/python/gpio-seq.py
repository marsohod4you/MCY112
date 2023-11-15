# Import module
import serial
import sys
import time

#arguments: SerialPortName, FileName, Address, Length
if len(sys.argv)<3 :
	print("Not enough arguments, need Serial Port name and GPIO id, for example:")
	print("python COM22 A")

gpio_a = ["3.3V","5V","GPIO2","5V","GPIO3","Gnd","GPIO4","GPIO14","Gnd","GPIO15","GPIO17","GPIO18","GPIO27"  ,"Gnd","GPIO22","GPIO23" ,"3.3V","GPIO24" ,"GPIO10","Gnd","GPIO9","GPIO25" ,"GPIO11"  ,"GPIO8","Gnd","GPIO7"   ,"GPIO0"   ,"GPIO1"   ,"GPIO5","Gnd","GPIO6","GPIO12","GPIO13","Gnd","GPIO19","GPIO16","GPIO26"  ,"GPIO20","Gnd","GPIO21"]
gpio_b = ["3.3V","5V","GPIO2","5V","GPIO3","Gnd","GPIO4","GPIO14","Gnd","GPIO15","GPIO17","GPIO18","GPIO27nc","Gnd","GPIO22","GPIO23i","3.3V","GPIO24i","GPIO10","Gnd","GPIO9","GPIO25i","GPIO11"  ,"GPIO8","Gnd","GPIO7"   ,"GPIO0"   ,"GPIO1"   ,"GPIO5","Gnd","GPIO6","GPIO12","GPIO13","Gnd","GPIO19","GPIO16","GPIO26nc","GPIO20","Gnd","GPIO21"]
gpio_c = ["3.3V","5V","GPIO2","5V","GPIO3","Gnd","GPIO4","GPIO14","Gnd","GPIO15","GPIO17","GPIO18","GPIO27"  ,"Gnd","GPIO22","GPIO23" ,"3.3V","GPIO24" ,"GPIO10","Gnd","GPIO9","GPIO25" ,"JTAG-TDI","GPIO8","Gnd","JTAG-TCK","JTAG-TMS","JTAG-TDO","GPIO5","Gnd","GPIO6","GPIO12","GPIO13","Gnd","GPIO19","GPIO16","GPIO26"  ,"GPIO20","Gnd","GPIO21"]

GPIO_N=1
GPIO_L=gpio_a
if sys.argv[2]=="A" :
	GPIO_N=1
	GPIO_L=gpio_a
elif sys.argv[2]=="B" :
	GPIO_N=2
	GPIO_L=gpio_b
elif sys.argv[2]=="C" :
	GPIO_N=3
	GPIO_L=gpio_c

port_name = sys.argv[1]
port = serial.Serial()
port.baudrate=115200
port.port=port_name
port.bytesize=8
port.parity='N'
port.stopbits=1
#port.write_timeout=0;
port.open()
print("Serial port:",port.name)

def set_pin_val(conn_id,pin,val):
	ba=bytearray(2)
	ba[0]=0x80 | (conn_id&3) | ((val&1)<<2)
	ba[1]=pin & 0x7F
	port.write( ba )

#turn OFF all pins
def zero_all():
	print("Turn OFF all pins..")
	for pin in GPIO_L :
		if "i" in pin :
			continue
		if "nc" in pin :
			continue
		if "GPIO" in pin :
			#print(pin)
			pinN=int(pin[4:])
			set_pin_val(GPIO_N,pinN,0)

zero_all()
print("Turn ON pins sequentally")
time.sleep(3)

#turn ON all pins sequentally
for pin in GPIO_L :
	if "i" in pin :
		continue
	if "nc" in pin :
		continue
	if "GPIO" in pin :
		print(pin)
		pinN=int(pin[4:])
		set_pin_val(GPIO_N,pinN,1)
		time.sleep(1)

time.sleep(3)
zero_all()
