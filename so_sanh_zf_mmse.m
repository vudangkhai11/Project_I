clear; clc; close all;
cfg = config_params();
cfg.N_sym = 2000;               % 800 frame chạy mất khoảng 1 phút
cfg.snr_db = 4:2:18;           % Dải SNR
cfg.iter_list = 6;             % Dùng mốc 6 vòng lặp tối ưu vừa tìm được

rng(cfg.seed);
pi = randperm(cfg.K_info).';
invpi = zeros(cfg.K_info, 1);
invpi(pi) = (1:cfg.K_info).';

ber_zf = zeros(numel(cfg.snr_db), 1);
ber_mmse = zeros(numel(cfg.snr_db), 1);

fprintf('--- DANG CHAY SO SANH ZF VS MMSE (64-QAM, Turbo 6 iters) ---\n');
for iSNR = 1:numel(cfg.snr_db)
    snrDb = cfg.snr_db(iSNR);
    snrLin = 10^(snrDb / 10);
    err_zf = 0; err_mmse = 0; tot = 0;

    for f = 1:cfg.N_sym
        s_zf   = simulate_frame(cfg, pi, invpi, snrLin, 'zf');
        s_mmse = simulate_frame(cfg, pi, invpi, snrLin, 'mmse');

        err_zf   = err_zf + s_zf.bit_err_post(1);
        err_mmse = err_mmse + s_mmse.bit_err_post(1);
        tot      = tot + s_zf.bit_tot;
    end
    ber_zf(iSNR)   = err_zf / tot;
    ber_mmse(iSNR) = err_mmse / tot;
    fprintf('SNR = %2d dB | BER_ZF = %.3e | BER_MMSE = %.3e\n', snrDb, ber_zf(iSNR), ber_mmse(iSNR));
end

% Vẽ đồ thị so sánh ZF vs MMSE
figure('Color', 'w', 'Position', [100, 100, 750, 480]);
semilogy(cfg.snr_db, ber_zf, 'r-o', 'LineWidth', 2, 'MarkerFaceColor', 'r', 'DisplayName', 'ZF Equalizer');
hold on;
semilogy(cfg.snr_db, ber_mmse, 'b-s', 'LineWidth', 2, 'MarkerFaceColor', 'b', 'DisplayName', 'MMSE Equalizer');
grid on; grid minor;
xlim([4 16]);
ylim([1e-5 1]);
xlabel('SNR (dB)', 'FontSize', 12);
ylabel('Tỉ lệ lỗi bit (BER)', 'FontSize', 12);
title('So sánh hiệu năng cân bằng ZF vs MMSE (2x2 MIMO-OFDM, 64-QAM, Turbo 6 vòng)', 'FontSize', 13);
legend('Location', 'southwest', 'FontSize', 11);

exportgraphics(gcf, 'so_sanh_zf_mmse.png', 'Resolution', 300);
fprintf('\nDa luu anh thanh cong: so_sanh_zf_mmse.png!\n');