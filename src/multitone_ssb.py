from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt

from ssb_core import make_time_axis, multitone, ssb_modulate, coherent_demodulate, spectrum

RESULTS_DIR = Path(__file__).resolve().parent.parent / "results"
RESULTS_DIR.mkdir(exist_ok=True)

fs = 32000
duration = 0.05
tone_freqs = [300, 700, 1200]
fc = 8000
lpf_cutoff = 1800

t = make_time_axis(fs, duration)
message = multitone(t, tone_freqs)

usb = ssb_modulate(message, t, fc, sideband="usb")
lsb = ssb_modulate(message, t, fc, sideband="lsb")

recovered_usb = coherent_demodulate(usb, t, fc, lpf_cutoff, fs)
recovered_lsb = coherent_demodulate(lsb, t, fc, lpf_cutoff, fs)

f_usb, m_usb = spectrum(usb, fs)
f_lsb, m_lsb = spectrum(lsb, fs)

fig, axes = plt.subplots(3, 1, figsize=(9, 9))

window = t < 10 / min(tone_freqs)
axes[0].plot(t[window] * 1e3, message[window], label="multitone message m(t)")
axes[0].set_xlabel("time (ms)")
axes[0].set_ylabel("amplitude")
axes[0].set_title(f"multitone message, tones = {tone_freqs} Hz")
axes[0].legend()

axes[1].plot(f_usb, m_usb, label="USB spectrum")
axes[1].plot(f_lsb, m_lsb, label="LSB spectrum", alpha=0.8)
axes[1].axvline(fc, color="gray", linestyle="--", linewidth=1, label="carrier fc")
axes[1].set_xlim(max(0, fc - 2000), fc + 2000)
axes[1].set_xlabel("frequency (Hz)")
axes[1].set_ylabel("magnitude")
axes[1].set_title("spectrum of USB and LSB SSB-SC signals for the multitone message")
axes[1].legend()

axes[2].plot(t[window] * 1e3, message[window], label="original message")
axes[2].plot(t[window] * 1e3, recovered_usb[window], "--", label="recovered from USB")
axes[2].plot(t[window] * 1e3, recovered_lsb[window], ":", label="recovered from LSB")
axes[2].set_xlabel("time (ms)")
axes[2].set_ylabel("amplitude")
axes[2].set_title("coherent detector output vs original multitone message")
axes[2].legend()

fig.tight_layout()
out_path = RESULTS_DIR / "multitone_ssb.png"
fig.savefig(out_path, dpi=150)
print(f"saved {out_path}")

error_usb = np.sqrt(np.mean((recovered_usb - message) ** 2))
error_lsb = np.sqrt(np.mean((recovered_lsb - message) ** 2))
print(f"RMS recovery error (USB path) = {error_usb:.5f}")
print(f"RMS recovery error (LSB path) = {error_lsb:.5f}")
