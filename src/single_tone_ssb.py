from pathlib import Path

import numpy as np
import matplotlib.pyplot as plt

from ssb_core import make_time_axis, tone, ssb_modulate, coherent_demodulate, spectrum, magnitude_at

RESULTS_DIR = Path(__file__).resolve().parent.parent / "results"
RESULTS_DIR.mkdir(exist_ok=True)

fs = 32000
duration = 0.05
fm = 1000
fc = 8000
lpf_cutoff = 1500

t = make_time_axis(fs, duration)
message = tone(t, fm)

usb = ssb_modulate(message, t, fc, sideband="usb")
lsb = ssb_modulate(message, t, fc, sideband="lsb")

recovered_usb = coherent_demodulate(usb, t, fc, lpf_cutoff, fs)
recovered_lsb = coherent_demodulate(lsb, t, fc, lpf_cutoff, fs)

f_usb, m_usb = spectrum(usb, fs)
f_lsb, m_lsb = spectrum(lsb, fs)

usb_wanted = magnitude_at(f_usb, m_usb, fc + fm)
usb_suppressed = magnitude_at(f_usb, m_usb, fc - fm)
lsb_wanted = magnitude_at(f_lsb, m_lsb, fc - fm)
lsb_suppressed = magnitude_at(f_lsb, m_lsb, fc + fm)

print(f"USB: wanted tone at fc+fm = {usb_wanted:.5f}, opposite sideband leakage = {usb_suppressed:.5f}")
print(f"USB sideband suppression = {20 * np.log10(usb_wanted / usb_suppressed):.1f} dB")
print(f"LSB: wanted tone at fc-fm = {lsb_wanted:.5f}, opposite sideband leakage = {lsb_suppressed:.5f}")
print(f"LSB sideband suppression = {20 * np.log10(lsb_wanted / lsb_suppressed):.1f} dB")

fig, axes = plt.subplots(3, 1, figsize=(9, 9))

window = t < 4 / fm
axes[0].plot(t[window] * 1e3, message[window], label="message m(t)")
axes[0].plot(t[window] * 1e3, usb[window], label="USB SSB-SC s(t)", alpha=0.8)
axes[0].set_xlabel("time (ms)")
axes[0].set_ylabel("amplitude")
axes[0].set_title(f"single tone message ({fm} Hz) and its USB SSB-SC waveform")
axes[0].legend()

axes[1].plot(f_usb, m_usb, label="USB spectrum")
axes[1].plot(f_lsb, m_lsb, label="LSB spectrum", alpha=0.8)
axes[1].axvline(fc, color="gray", linestyle="--", linewidth=1, label="carrier fc")
axes[1].set_xlim(max(0, fc - 4 * fm), fc + 4 * fm)
axes[1].set_xlabel("frequency (Hz)")
axes[1].set_ylabel("magnitude")
axes[1].set_title("spectrum of USB and LSB SSB-SC signals (carrier + one sideband suppressed)")
axes[1].legend()

axes[2].plot(t[window] * 1e3, message[window], label="original message")
axes[2].plot(t[window] * 1e3, recovered_usb[window], "--", label="recovered from USB")
axes[2].plot(t[window] * 1e3, recovered_lsb[window], ":", label="recovered from LSB")
axes[2].set_xlabel("time (ms)")
axes[2].set_ylabel("amplitude")
axes[2].set_title("coherent detector output vs original message")
axes[2].legend()

fig.tight_layout()
out_path = RESULTS_DIR / "single_tone_ssb.png"
fig.savefig(out_path, dpi=150)
print(f"saved {out_path}")
