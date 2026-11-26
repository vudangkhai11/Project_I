clear; clc; close all;
cfg = config_params();

% Khảo sát 1000 frame tại SNR = 12 dB (vùng nhạy cảm nhất của 64-QAM)
cfg.N_sym = 2000;          
snrTestDb = 12;           
snrLin = 10^(snrTestDb / 10);

% Khảo sát từ vòng 1 đến vòng 10
iterList = 1:10; 
cfg.iter_list = iterList;

rng(cfg.seed);
pi = randperm(cfg.K_info).';
invpi = zeros(cfg.K_info, 1);
invpi(pi) = (1:cfg.K_info).';

bitErrPost = zeros(numel(iterList), 1);
bitTot = 0;

fprintf('Dang khao sat tu vong 1 den 10 tai SNR = %d dB (khoang 40 giay)...\n', snrTestDb);
for f = 1:cfg.N_sym
    s = simulate_frame(cfg, pi, invpi, snrLin);
    bitErrPost = bitErrPost + s.bit_err_post;
    bitTot = bitTot + s.bit_tot;
end

ber_iters = bitErrPost / bitTot;

% In ket qua ra man hinh
fprintf('\n--- KET QUA BER THEO SO VONG LAP ---\n');
for i = 1:10
    fprintf('Vong %2d: BER = %.4e\n', i, ber_iters(i));
end

% Ve do thi tim gioi han
figure('Color', 'w', 'Position', [100, 100, 750, 480]);
semilogy(iterList, ber_iters, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b', 'MarkerSize', 7);
grid on; grid minor;
xlabel('Số vòng lặp giải mã Turbo (Iterations)', 'FontSize', 12);
ylabel('Tỉ lệ lỗi bit (BER)', 'FontSize', 12);
title(sprintf('Khảo sát giới hạn hội tụ của mã Turbo (SNR = %d dB, 64-QAM)', snrTestDb), 'FontSize', 13);
xticks(1:10);

% Danh dau gioi han tren do thi
%hold on;
%plot(6, ber_iters(6), 'rp', 'MarkerSize', 15, 'MarkerFaceColor', 'r');
%text(6.2, ber_iters(6), ' \leftarrow Giới hạn hội tụ (~6 vòng)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'r');

% Luu anh chat luong cao
exportgraphics(gcf, 'gioi_han_vong_lap.png', 'Resolution', 300);
fprintf('\nDa luu anh thanh cong: gioi_han_vong_lap.png!\n');