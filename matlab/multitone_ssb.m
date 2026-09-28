fs = 32000;
duration = 0.05;
tone_freqs = [300 700 1200];
fc = 8000;
lpf_cutoff = 1800;

t = 0:1/fs:duration-1/fs;
message = make_multitone(t, tone_freqs);

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

error_usb = sqrt(mean((recovered_usb - message).^2));
error_lsb = sqrt(mean((recovered_lsb - message).^2));
fprintf('RMS recovery error (USB path) = %.5f\n', error_usb);
fprintf('RMS recovery error (LSB path) = %.5f\n', error_lsb);

window = t < 10/min(tone_freqs);

figure('Position', [100 100 900 900]);

subplot(3,1,1);
plot(t(window)*1e3, message(window), 'DisplayName', 'multitone message m(t)');
xlabel('time (ms)'); ylabel('amplitude');
title(sprintf('multitone message, tones = [%s] Hz', num2str(tone_freqs)));
legend;

subplot(3,1,2);
plot(f_axis, usb_spec, 'DisplayName', 'USB spectrum');
hold on;
plot(f_axis, lsb_spec, 'DisplayName', 'LSB spectrum');
xline(fc, '--', 'DisplayName', 'carrier fc');
xlim([max(0, fc - 2000), fc + 2000]);
xlabel('frequency (Hz)'); ylabel('magnitude');
title('spectrum of USB and LSB SSB-SC signals for the multitone message');
legend;

subplot(3,1,3);
plot(t(window)*1e3, message(window), 'DisplayName', 'original message');
hold on;
plot(t(window)*1e3, recovered_usb(window), '--', 'DisplayName', 'recovered from USB');
plot(t(window)*1e3, recovered_lsb(window), ':', 'DisplayName', 'recovered from LSB');
xlabel('time (ms)'); ylabel('amplitude');
title('coherent detector output vs original multitone message');
legend;

saveas(gcf, fullfile(fileparts(mfilename('fullpath')), 'results', 'multitone_ssb.png'));
fprintf('saved results/multitone_ssb.png\n');
