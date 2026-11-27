function stats = simulate_frame(cfg, pi, invpi, snrLin, eqType)
%SIMULATE_FRAME Run one Turbo frame across N_ofdm OFDM symbols.
if nargin < 5, eqType = 'zf'; end

infoBits = randi([0 1], cfg.K_info, 1);
codedBits = turbo_stage('encode', infoBits, pi);
bitsFrame = [codedBits; zeros(cfg.bits_pad, 1)];
txSymsAll = qam16_stage('mod', bitsFrame);
totalSyms = numel(txSymsAll);
rxSymsAll = zeros(totalSyms, 1);
noiseVarAll = zeros(totalSyms, 1);

for iSym = 1:cfg.N_ofdm
    idx = (iSym - 1) * cfg.sym_per_ofdm + (1:cfg.sym_per_ofdm);
    txFreq = reshape(txSymsAll(idx), cfg.N, cfg.nTx) / sqrt(cfg.nTx);
    txTimeCp = ofdm_stage('mod', txFreq, cfg);
    [rxTime, Hfreq, noisePowerTime] = channel_stage(txTimeCp, snrLin, cfg);
    rxFreq = ofdm_stage('demod', rxTime, cfg);

    [rxSyms, noiseEnh] = mimo_zf_stage('detect', rxFreq, Hfreq, cfg, eqType, snrLin);

    rxSymsAll(idx) = rxSyms(:) * sqrt(cfg.nTx);
    sigma2Rx = cfg.N * noisePowerTime;
    noiseVarAll(idx) = cfg.nTx * sigma2Rx * [noiseEnh(:, 1); noiseEnh(:, 2)];
end

rxSymsUsed = rxSymsAll(1:cfg.Ns_used);
[~, llrVec] = qam16_stage('llr', rxSymsUsed, noiseVarAll(1:cfg.Ns_used));

stats.bit_tot = cfg.K_info;
Lsys = llrVec(1:cfg.K_info);
Lp1 = llrVec(cfg.K_info+1:2*cfg.K_info);
Lp2 = llrVec(2*cfg.K_info+1:3*cfg.K_info);

stats.bit_err_post = zeros(numel(cfg.iter_list), 1);
for iIter = 1:numel(cfg.iter_list)
    decBits = turbo_stage('decode', Lsys, Lp1, Lp2, pi, invpi, cfg.iter_list(iIter));
    stats.bit_err_post(iIter) = sum(decBits ~= infoBits);
end
end
