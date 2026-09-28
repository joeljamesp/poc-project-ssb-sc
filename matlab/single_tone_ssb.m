fs = 32000;
duration = 0.05;
fm = 1000;
fc = 8000;
lpf_cutoff = 1500;

t = 0:1/fs:duration-1/fs;
message = cos(2*pi*fm*t);

usb = ssb_modulate(message, t, fc, 'usb');
lsb = ssb_modulate(message, t, fc, 'lsb');

recovered_usb = coherent_demod(usb, t, fc, lpf_cutoff, fs);
recovered_lsb = coherent_demod(lsb, t, fc, lpf_cutoff, fs);

n = numel(usb);
f_axis = (0:n/2) * fs / n;
usb_spec = abs(fft(usb)) / n;
usb_spec = usb_spec(1:n/2+1);
lsb_spec = abs(fft(lsb)) / n;
lsb_spec = lsb_spec(1:n/2+1);

[~, idx_wanted_usb] = min(abs(f_axis - (fc + fm)));
[~, idx_leak_usb] = min(abs(f_axis - (fc - fm)));
[~, idx_wanted_lsb] = min(abs(f_axis - (fc - fm)));
[~, idx_leak_lsb] = min(abs(f_axis - (fc + fm)));

usb_suppression_db = 20*log10(usb_spec(idx_wanted_usb) / usb_spec(idx_leak_usb));
lsb_suppression_db = 20*log10(lsb_spec(idx_wanted_lsb) / lsb_spec(idx_leak_lsb));

fprintf('USB sideband suppression = %.1f dB\n', usb_suppression_db);
fprintf('LSB sideband suppression = %.1f dB\n', lsb_suppression_db);

window = t < 4/fm;

figure('Position', [100 100 900 900]);

subplot(3,1,1);
plot(t(window)*1e3, message(window), 'DisplayName', 'message m(t)');
hold on;
plot(t(window)*1e3, usb(window), 'DisplayName', 'USB SSB-SC s(t)');
xlabel('time (ms)'); ylabel('amplitude');
title(sprintf('single tone message (%d Hz) and its USB SSB-SC waveform', fm));
legend;

subplot(3,1,2);
plot(f_axis, usb_spec, 'DisplayName', 'USB spectrum');
hold on;
plot(f_axis, lsb_spec, 'DisplayName', 'LSB spectrum');
xline(fc, '--', 'DisplayName', 'carrier fc');
xlim([max(0, fc - 4*fm), fc + 4*fm]);
xlabel('frequency (Hz)'); ylabel('magnitude');
title('spectrum of USB and LSB SSB-SC signals (carrier + one sideband suppressed)');
legend;

subplot(3,1,3);
plot(t(window)*1e3, message(window), 'DisplayName', 'original message');
hold on;
plot(t(window)*1e3, recovered_usb(window), '--', 'DisplayName', 'recovered from USB');
plot(t(window)*1e3, recovered_lsb(window), ':', 'DisplayName', 'recovered from LSB');
xlabel('time (ms)'); ylabel('amplitude');
title('coherent detector output vs original message');
legend;

saveas(gcf, fullfile(fileparts(mfilename('fullpath')), 'results', 'single_tone_ssb.png'));
fprintf('saved results/single_tone_ssb.png\n');
