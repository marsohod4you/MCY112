import time
import sys
import subprocess

if len(sys.argv)<2 :
	print("Need argument: COM-port name")
	sys.exit()

print("Cmdline:",sys.argv)
port_name = sys.argv[1]
subprocess.run(["python", "img2serial.py", port_name, "cat0.jpg", "100", "100"])
subprocess.run(["python", "img2serial.py", port_name, "cat1.jpg", "300", "150"])
subprocess.run(["python", "img2serial.py", port_name, "cat2.jpg", "700", "50"])
subprocess.run(["python", "img2serial.py", port_name, "cat3.jpg", "400", "300"])

