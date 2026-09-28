function h = hilbert_fir_coeffs(num_taps)
    if mod(num_taps, 2) == 0
        num_taps = num_taps + 1;
    end
    h = firpm(num_taps - 1, [0.04 0.96], [1 1], 'hilbert');
end
