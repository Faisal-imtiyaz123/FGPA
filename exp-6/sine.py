import numpy as np
import scipy.signal as signal
import matplotlib.pyplot as plt

# PARAMETERS
Fs = 10000
Fc = 1000
num_taps = 100
duration = 0.02
freqs = [950, 1100, 2000]

SCALE = 2**14

# FIXED POINT FUNCTIONS
def float_to_q214(x):
    return np.round(x * SCALE).astype(np.int16)

def save_hex(filename, data):
    with open(filename, "w") as f:
        for val in data:
            val_uint = np.uint16(val)
            f.write(format(val_uint, '04x') + "\n")

# DESIGN FIR
cutoff_norm = Fc / (Fs/2)
h_float = signal.firwin(num_taps, cutoff_norm)
h_q = float_to_q214(h_float)

def save_float(filename, data):
    np.savetxt(filename, data, fmt="%.8f")

save_float("fir_coeff_float.txt", h_float)
print("Float coefficients saved!")
save_hex("fir_coeff_q214.txt", h_q)

#GENERATE SINE SIGNALS & PLOT PYTHON OUTPUT
t = np.arange(0, duration, 1/Fs)

for f in freqs:
    # Generate and save input signal
    sig = np.sin(2*np.pi*f*t)
    sig_q = float_to_q214(sig)
    save_hex(f"sine{f}_Q214.txt", sig_q)

    # Python filtering
    y = signal.lfilter(h_float, 1.0, sig)

    # Plot
    plt.figure(figsize=(8, 4))
    plt.plot(t, y, label=f'Filtered Output ({f} Hz)', color='blue')
    plt.title(f"Python FIR Output - {f} Hz")
    plt.xlabel("Time (s)")
    plt.ylabel("Amplitude")
    plt.grid(True)
    plt.legend()
    plt.show()

print("Python reference plots generated.")
print("HEX files generated for Verilog testbenches.")