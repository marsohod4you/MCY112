# Import module
import serial
import sys
from tkinter import *

#arguments: SerialPortName, FileName, Address, Length
if len(sys.argv)<2 :
	print("Not enough arguments, need Serial Port name")
	
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

# Create object
root = Tk()
root.title("MCY112 GPIO Test")

# Adjust size
root.geometry("690x560")

# Add image file
bg = PhotoImage(file = "background.png")

# Show image using label
canvas1 = Canvas( root, width=690, height=560)
canvas1.place(x = 0, y = 0)
canvas1.create_image(0,0,anchor=NW,image=bg)

gpio_a = ["3.3V","5V","GPIO2","5V","GPIO3","Gnd","GPIO4","GPIO14","Gnd","GPIO15","GPIO17","GPIO18","GPIO27"  ,"Gnd","GPIO22","GPIO23" ,"3.3V","GPIO24" ,"GPIO10","Gnd","GPIO9","GPIO25" ,"GPIO11"  ,"GPIO8","Gnd","GPIO7"   ,"GPIO0"   ,"GPIO1"   ,"GPIO5","Gnd","GPIO6","GPIO12","GPIO13","Gnd","GPIO19","GPIO16","GPIO26"  ,"GPIO20","Gnd","GPIO21"]
gpio_b = ["3.3V","5V","GPIO2","5V","GPIO3","Gnd","GPIO4","GPIO14","Gnd","GPIO15","GPIO17","GPIO18","GPIO27nc","Gnd","GPIO22","GPIO23i","3.3V","GPIO24i","GPIO10","Gnd","GPIO9","GPIO25i","GPIO11"  ,"GPIO8","Gnd","GPIO7"   ,"GPIO0"   ,"GPIO1"   ,"GPIO5","Gnd","GPIO6","GPIO12","GPIO13","Gnd","GPIO19","GPIO16","GPIO26nc","GPIO20","Gnd","GPIO21"]
gpio_c = ["3.3V","5V","GPIO2","5V","GPIO3","Gnd","GPIO4","GPIO14","Gnd","GPIO15","GPIO17","GPIO18","GPIO27"  ,"Gnd","GPIO22","GPIO23" ,"3.3V","GPIO24" ,"GPIO10","Gnd","GPIO9","GPIO25" ,"JTAG-TDI","GPIO8","Gnd","JTAG-TCK","JTAG-TMS","JTAG-TDO","GPIO5","Gnd","GPIO6","GPIO12","GPIO13","Gnd","GPIO19","GPIO16","GPIO26"  ,"GPIO20","Gnd","GPIO21"]

def get_color(g):
	if "JTAG" in g:
		return 'blue'
	elif "nc" in g:
		return 'white'
	elif "i" in g:
		return 'violet'
	elif g=="3.3V" :
		return 'orange'
	elif g=="5V" :
		return 'red'
	elif g=="Gnd" :
		return 'black'
	else :
		return 'green'

def check_click_a(orgx,orgy,x,y) :
	D=10
	S=12
	if x>=orgx and x<(orgx+S*20) and y>=orgy and y<(orgy+S+S) :
		xx=(x-orgx)//S
		yy=(y-orgy)//S
		return gpio_a[xx*2+1-yy]
	return "?"

def check_click_b(orgx,orgy,x,y) :
	D=10
	S=12
	if x>=orgx and x<(orgx+S*20) and y>=orgy and y<(orgy+S+S) :
		xx=(x-orgx)//S
		yy=(y-orgy)//S
		return gpio_b[(19-xx)*2+yy]
	return "?"

def check_click_c(orgx,orgy,x,y) :
	D=10
	S=12
	if x>=orgx and x<(orgx+S+S) and y>=orgy and y<(orgy+S*20) :
		xx=(x-orgx)//S
		yy=(y-orgy)//S
		return gpio_c[yy*2+xx]
	return "?"

state_a=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
state_b=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
state_c=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
oval_a=[]
oval_b=[]
oval_c=[]

def invert_val(state,oval,idx,oval_idx):
	state[idx]=state[idx]^1
	crl='green'
	if state[idx] :
		crl='lightgreen'
	canvas1.itemconfig(oval[oval_idx], fill=crl)
	return state[idx]

def paint_gpio_a(canvas,x,y):
	i=0
	D=10
	S=12
	while i<20:
		g= get_color( gpio_a[i*2] )
		o1=canvas.create_oval(x+S*i, y+S, x+S*i+D, y+D+S,
             fill=g, outline="blue",
             width=1)
		oval_a.append(o1)
		g= get_color( gpio_a[i*2+1] )
		o2=canvas.create_oval(x+S*i, y, x+S*i+D, y+D,
             fill=g, outline="blue",
             width=1)
		oval_a.append(o2)
		i=i+1;

def paint_gpio_b(canvas,x,y):
	i=0
	D=10
	S=12
	while i<20:
		g= get_color( gpio_b[(19-i)*2+1] )
		o1=canvas.create_oval(x+S*i, y+S, x+S*i+D, y+D+S,
             fill=g, outline="blue",
             width=1)
		oval_b.insert(0,o1)
		g= get_color( gpio_b[(19-i)*2] )
		o2=canvas.create_oval(x+S*i, y, x+S*i+D, y+D,
             fill=g, outline="blue",
             width=1)
		oval_b.insert(0,o2)
		i=i+1;

def paint_gpio_c(canvas,x,y):
	i=0
	D=10
	S=12
	while i<20:
		g= get_color( gpio_c[i*2+1] )
		o1=canvas.create_oval(x+S, y+S*i, x+S+D, y+D+S*i,
             fill=g, outline="blue",
             width=1)
		g= get_color( gpio_c[i*2] )
		o2=canvas.create_oval(x, y+S*i, x+D, y+D+S*i,
             fill=g, outline="blue",
             width=1)
		oval_c.append(o2)
		oval_c.append(o1)
		i=i+1;

def canvas_clicked(event):
	pin=check_click_a(150,50,event.x,event.y)
	if "nc" in pin:
		print(pin)
		return
	elif "i" in pin:
		print(pin)
		return
	if pin!="?" :
		print("A "+pin)
		if "GPIO" in pin:
			pinN=int(pin[4:])
			val = invert_val(state_a,oval_a,pinN,gpio_a.index(pin))
			set_pin_val(1,pinN,val)
		return
	pin = check_click_c(110,140,event.x,event.y)
	if "nc" in pin:
		print(pin)
		return
	elif "i" in pin:
		print(pin)
		return
	if pin!="?" :
		print("C "+pin)
		if "GPIO" in pin:
			pinN=int(pin[4:])
			val = invert_val(state_c,oval_c,pinN,gpio_c.index(pin))
			set_pin_val(3,pinN,val)
		return
	pin = check_click_b(150,460,event.x,event.y)
	if "nc" in pin:
		print(pin)
		return
	elif "i" in pin:
		print(pin)
		return
	if pin!="?" :
		print("B "+pin)
		if "GPIO" in pin:
			pinN=int(pin[4:])
			val = invert_val(state_b,oval_b,pinN,gpio_b.index(pin))
			set_pin_val(2,pinN,val)
		return
	return "?"

canvas1.bind("<Button-1>", canvas_clicked)
paint_gpio_a(canvas1,150,50)
paint_gpio_b(canvas1,150,460)
paint_gpio_c(canvas1,110,140)

# Create Frame
frame1 = Frame(root)
frame1.pack(pady = 20 )

# Execute tkinter
root.mainloop()
