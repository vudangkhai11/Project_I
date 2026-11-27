clear; clc; close all;
cfg = config_params();
cfg.N_sym = 2000;
cfg.snr_db = 4:1:16;
cfg.iter_list = 6;

% Block interleaver 32x32 cho khung Turbo 1024 bit.
matIdx = reshape(1:cfg.K_info, 32, 32);
pi = reshape(matIdx.', [], 1);
invpi = zeros(cfg.K_info, 1);
invpi(pi) = (1:cfg.K_info).';

ber_zf = zeros(numel(cfg.snr_db), 1);
ber_mmse = zeros(numel(cfg.snr_db), 1);

fprintf('--- DANG CHAY CO DINH %d FRAMES (64-QAM, K=%d, Block Interleaver) ---\n', cfg.N_sym, cfg.K_info);
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
    fprintf('SNR = %2d dB | BER_ZF = %.3e | BER_MMSE = %.3e\n', ...
        snrDb, ber_zf(iSNR), ber_mmse(iSNR));
end

figure('Color', 'w', 'Position', [100, 100, 750, 480]);
semilogy(cfg.snr_db, ber_zf, 'r-o', 'LineWidth', 2, 'MarkerFaceColor', 'r', 'DisplayName', 'ZF Equalizer (Turbo 6 iters)');
hold on;
semilogy(cfg.snr_db, ber_mmse, 'b-s', 'LineWidth', 2, 'MarkerFaceColor', 'b', 'DisplayName', 'MMSE Equalizer (Turbo 6 iters)');
grid on; grid minor;
xlim([4 16]);
ylim([1e-6 1]);
xlabel('SNR (dB)', 'FontSize', 12);
ylabel('Tỉ lệ lỗi bit (BER)', 'FontSize', 12);
title('So sánh ZF và MMSE (2×2 MIMO-OFDM, 64-QAM, Turbo 6 vòng)', 'FontSize', 11);
legend('Location', 'southwest', 'FontSize', 10);

if ~exist('docs/images', 'dir')
    mkdir('docs/images');
end
exportgraphics(gcf, 'docs/images/so_sanh_zf_mmse_2000frame.png', 'Resolution', 300);
fprintf('\nDa luu anh thanh cong: docs/images/so_sanh_zf_mmse_2000frame.png!\n');
