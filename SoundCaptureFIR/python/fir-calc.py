import numpy as np
from scipy import signal
import matplotlib.pyplot as plt

num_taps = 501 # it helps to use an odd number of taps
cut_off = [600.0, 2200.0] # Hz
sample_rate = 46875 # Hz

# create our low pass filter
#T = signal.firwin(num_taps, cut_off, window = "hamming", fs=sample_rate )
T = signal.firwin(num_taps, cutoff = cut_off, window = "hamming", fs=sample_rate, pass_zero = False)
Ta = np.array(T)
Ta_abs_max = np.amax(np.abs(Ta))
Ta_scaled = Ta*(32766/Ta_abs_max)
Ta_scaled_int = Ta_scaled.astype(int)
print( Ta )
print( Ta_scaled_int )
np.savetxt('fir-coeffs.txt', Ta_scaled_int, fmt='%d' ) 

print("========= Altera Memory Initialization File ===================")
print("WIDTH = 16;")
print("DEPTH = 512;")
print("ADDRESS_RADIX = HEX;")
print("DATA_RADIX = HEX;")
print("CONTENT BEGIN")
i=0
while i < len(Ta_scaled_int) :
	print( f"{i:04x}",":", f"{Ta_scaled_int[i]&0xffff:04x}",";")
	i=i+1
print("END")
print("================================================================")

w, h = signal.freqz(T,fs=sample_rate,include_nyquist=False)

fig, ax1 = plt.subplots()
ax1.set_title('Digital filter frequency response')
ax1.plot(w, 20 * np.log10(abs(h)), 'b')
ax1.set_ylabel('Amplitude [dB]', color='b')
ax1.set_xlabel('Frequency [rad/sample]')
ax2 = ax1.twinx()
angles = np.unwrap(np.angle(h))
ax2.plot(w, angles, 'g')
ax2.set_ylabel('Angle (radians)', color='g')
ax2.grid(True)
ax2.axis('tight')
plt.show()
