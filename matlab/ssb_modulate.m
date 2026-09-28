function s = ssb_modulate(message, t, fc, sideband, num_taps)
    if nargin < 5
        num_taps = 129;
    end
    h = hilbert_fir_coeffs(num_taps);
    message_hat = conv(message, h, 'same');
    cos_c = cos(2*pi*fc*t);
    sin_c = sin(2*pi*fc*t);
    if strcmp(sideband, 'usb')
        s = message .* cos_c - message_hat .* sin_c;
    elseif strcmp(sideband, 'lsb')
        s = message .* cos_c + message_hat .* sin_c;
    else
        error('sideband must be usb or lsb');
    end
end
