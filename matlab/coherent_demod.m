function recovered = coherent_demod(ssb_signal, t, fc, cutoff, fs, order)
    if nargin < 6
        order = 5;
    end
    mixed = ssb_signal .* cos(2*pi*fc*t);
    nyquist = fs / 2;
    [b, a] = butter(order, cutoff / nyquist, 'low');
    recovered = 2 * filtfilt(b, a, mixed);
end
