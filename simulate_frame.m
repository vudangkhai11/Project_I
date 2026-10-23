function stats = simulate_frame(cfg, pi, invpi, snrLin)
%SIMULATE_FRAME Run one transmitter-channel-receiver frame and count errors.
infoBits = randi([0 1], cfg.K_info, 1);
codedBits = turbo_stage('encode', infoBits, pi);
bitsFrame = [codedBits; zeros(cfg.bits_pad, 1)];
txSymsAll = qam16_stage('mod', bitsFrame);
txFreq = reshape(txSymsAll, cfg.N, cfg.nTx) / sqrt(cfg.nTx);
txTimeCp = ofdm_stage('mod', txFreq, cfg);
[rxTime, Hfreq, noisePowerTime] = channel_stage(txTimeCp, snrLin, cfg);
rxFreq = ofdm_stage('demod', rxTime, cfg);
[rxSyms, noiseEnh] = mimo_zf_stage('detect', rxFreq, Hfreq, cfg);
rxSymsVec = rxSyms(:);
% Bù hệ số chuẩn hóa 1/sqrt(nTx) đã áp dụng ở máy phát.
rxSymsVec = rxSymsVec * sqrt(cfg.nTx);
txSymsUsed = txSymsAll(1:cfg.Ns_used);
rxSymsUsed = rxSymsVec(1:cfg.Ns_used);

stats.bit_tot = cfg.K_info;
sigma2Rx = cfg.N * noisePowerTime;
% Phương sai sau ZF và sau khi tín hiệu được nhân sqrt(nTx).
noiseVarSym = cfg.nTx * sigma2Rx * ...
    [noiseEnh(:, 1); noiseEnh(:, 2)];
[~, llrVec] = qam16_stage('llr', rxSymsUsed, noiseVarSym(1:cfg.Ns_used));
Lsys = llrVec(1:cfg.K_info);
Lp1 = llrVec(cfg.K_info+1:2*cfg.K_info);
Lp2 = llrVec(2*cfg.K_info+1:3*cfg.K_info);
stats.bit_err_post = zeros(numel(cfg.iter_list), 1);

for iIter = 1:numel(cfg.iter_list)
    decBits = turbo_stage('decode', Lsys, Lp1, Lp2, ...
        pi, invpi, cfg.iter_list(iIter));

    stats.bit_err_post(iIter) = sum(decBits ~= infoBits);
end
