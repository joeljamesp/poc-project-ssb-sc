function m = make_multitone(t, freqs)
    m = zeros(size(t));
    for k = 1:numel(freqs)
        m = m + cos(2*pi*freqs(k)*t);
    end
    m = m / numel(freqs);
end
