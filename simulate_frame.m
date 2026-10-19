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
txSymsUsed = txSymsAll(1:cfg.Ns_used);
rxSymsUsed = rxSymsVec(1:cfg.Ns_used);

rxSymsHd = qam16_stage('hard', rxSymsUsed);
stats.sym_err_pre = sum(rxSymsHd ~= txSymsUsed);
stats.bit_tot = cfg.K_info;
sigma2Rx = cfg.N * noisePowerTime;
noiseVarSym = [sigma2Rx * noiseEnh(:, 1); sigma2Rx * noiseEnh(:, 2)];
[~, llrVec] = qam16_stage('llr', rxSymsUsed, noiseVarSym(1:cfg.Ns_used));
Lsys = llrVec(1:cfg.K_info);
Lp1 = llrVec(cfg.K_info+1:2*cfg.K_info);
Lp2 = llrVec(2*cfg.K_info+1:3*cfg.K_info);
stats.bit_err_pre = sum((Lsys < 0) ~= infoBits);

decBits = turbo_stage('decode', Lsys, Lp1, Lp2, pi, invpi, cfg.nIter);
stats.bit_err_post = sum(decBits ~= infoBits);
codedHat = turbo_stage('encode', decBits, pi);
symsHat = qam16_stage('mod', [codedHat; zeros(cfg.bits_pad, 1)]);
stats.sym_err_post = sum(symsHat(1:cfg.Ns_used) ~= txSymsUsed);
end
