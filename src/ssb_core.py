import numpy as np
from scipy.signal import remez, fftconvolve, butter, filtfilt


def make_time_axis(fs, duration):
    return np.arange(0, duration, 1 / fs)


def hilbert_fir(num_taps=129):
    if num_taps % 2 == 0:
        num_taps += 1
    return remez(num_taps, [0.02, 0.48], [1], type="hilbert", fs=1.0)


def hilbert_transform(x, num_taps=129):
    h = hilbert_fir(num_taps)
    return -fftconvolve(x, h, mode="same")


def tone(t, freq, amplitude=1.0, phase=0.0):
    return amplitude * np.cos(2 * np.pi * freq * t + phase)


def multitone(t, freqs, amplitudes=None):
    if amplitudes is None:
        amplitudes = [1.0 for _ in freqs]
    msg = np.zeros_like(t)
    for f, a in zip(freqs, amplitudes):
        msg += a * np.cos(2 * np.pi * f * t)
    return msg / len(freqs)


def ssb_modulate(message, t, fc, sideband="usb", num_taps=129):
    message_hat = hilbert_transform(message, num_taps)
    cos_c = np.cos(2 * np.pi * fc * t)
    sin_c = np.sin(2 * np.pi * fc * t)
    if sideband == "usb":
        return message * cos_c - message_hat * sin_c
    if sideband == "lsb":
        return message * cos_c + message_hat * sin_c
    raise ValueError("sideband must be 'usb' or 'lsb'")


def coherent_demodulate(ssb_signal, t, fc, cutoff, fs, order=5):
    mixed = ssb_signal * np.cos(2 * np.pi * fc * t)
    nyquist = fs / 2
    b, a = butter(order, cutoff / nyquist, btype="low")
    return 2 * filtfilt(b, a, mixed)


def spectrum(signal, fs):
    n = len(signal)
    freqs = np.fft.rfftfreq(n, d=1 / fs)
    mags = np.abs(np.fft.rfft(signal)) / n
    return freqs, mags


def magnitude_at(freqs, mags, target_freq):
    idx = np.argmin(np.abs(freqs - target_freq))
    return mags[idx]
