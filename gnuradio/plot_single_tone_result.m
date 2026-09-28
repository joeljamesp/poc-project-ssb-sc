data_dir = fullfile(fileparts(mfilename('fullpath')), 'data', 'single_tone');
results_dir = fullfile(fileparts(mfilename('fullpath')), 'results');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

fs = 32000;
fc = 8000;
fm = 1000;

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

[~, idx_wanted_usb] = min(abs(f_axis - (fc + fm)));
[~, idx_leak_usb] = min(abs(f_axis - (fc - fm)));
usb_suppression_db = 20*log10(usb_spec(idx_wanted_usb) / usb_spec(idx_leak_usb));
fprintf('USB sideband suppression = %.1f dB\n', usb_suppression_db);

settle = round(0.01 * fs);
err = sqrt(mean((recovered(settle:end) - message(settle:end)).^2));
fprintf('RMS recovery error (after filter settling) = %.5f\n', err);

window = t >= 15e-3 & t < 19e-3;

figure('Position', [100 100 900 900]);

subplot(3,1,1);
plot(t(window)*1e3, message(window), 'DisplayName', 'message m(t)');
hold on;
plot(t(window)*1e3, usb(window), 'DisplayName', 'USB SSB-SC s(t)');
xlabel('time (ms)'); ylabel('amplitude');
title(sprintf('GNU Radio output: single tone message (%d Hz) and USB SSB-SC waveform', fm));
legend;

subplot(3,1,2);
plot(f_axis, usb_spec, 'DisplayName', 'USB spectrum');
hold on;
plot(f_axis, lsb_spec, 'DisplayName', 'LSB spectrum');
xline(fc, '--', 'DisplayName', 'carrier fc');
xlim([max(0, fc - 4*fm), fc + 4*fm]);
xlabel('frequency (Hz)'); ylabel('magnitude');
title('spectrum of USB and LSB SSB-SC signals (GNU Radio hilbert\_fc output)');
legend;

subplot(3,1,3);
plot(t(window)*1e3, message(window), 'DisplayName', 'original message');
hold on;
plot(t(window)*1e3, recovered(window), '--', 'DisplayName', 'recovered (coherent detector)');
xlabel('time (ms)'); ylabel('amplitude');
title('GNU Radio coherent detector output vs original message');
legend;

saveas(gcf, fullfile(results_dir, 'single_tone_ssb_gnuradio.png'));
fprintf('saved results/single_tone_ssb_gnuradio.png\n');
