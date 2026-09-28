data_dir = fullfile(fileparts(mfilename('fullpath')), 'data', 'multitone');
results_dir = fullfile(fileparts(mfilename('fullpath')), 'results');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

fs = 32000;
fc = 8000;
tone_freqs = [300 700 1200];

message = read_gnuradio_dat(fullfile(data_dir, 'message.dat'));
usb = read_gnuradio_dat(fullfile(data_dir, 'usb.dat'));
lsb = read_gnuradio_dat(fullfile(data_dir, 'lsb.dat'));
recovered = read_gnuradio_dat(fullfile(data_dir, 'recovered.dat'));

n = numel(message);
t = (0:n-1)' / fs;

f_axis = (0:n/2) * fs / n;
usb_spec = abs(fft(usb)) / n;
usb_spec = usb_spec(1:n/2+1);
lsb_spec = abs(fft(lsb)) / n;
lsb_spec = lsb_spec(1:n/2+1);

settle = round(0.01 * fs);
[xc, lags] = xcorr(recovered(settle:end), message(settle:end));
[~, idx] = max(xc);
delay = lags(idx);
recovered_aligned = circshift(recovered, -delay);
fprintf('estimated receive chain group delay = %d samples\n', delay);

err = sqrt(mean((recovered_aligned(settle:end-abs(delay)) - message(settle:end-abs(delay))).^2));
fprintf('RMS recovery error (after alignment and filter settling) = %.5f\n', err);

window = t >= 10e-3 & t < 43e-3;

figure('Position', [100 100 900 900]);

subplot(3,1,1);
plot(t(window)*1e3, message(window), 'DisplayName', 'multitone message m(t)');
xlabel('time (ms)'); ylabel('amplitude');
title(sprintf('GNU Radio output: multitone message, tones = [%s] Hz', num2str(tone_freqs)));
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
plot(t(window)*1e3, recovered_aligned(window), '--', 'DisplayName', 'recovered (coherent detector, delay-aligned)');
xlabel('time (ms)'); ylabel('amplitude');
title('GNU Radio coherent detector output vs original multitone message');
legend;

saveas(gcf, fullfile(results_dir, 'multitone_ssb_gnuradio.png'));
fprintf('saved results/multitone_ssb_gnuradio.png\n');
