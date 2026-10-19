function results = run_simulation(cfg)
%RUN_SIMULATION Run the SNR sweep and aggregate frame error counters.
rng(cfg.seed);
pi = randperm(cfg.K_info).';
invpi = zeros(cfg.K_info, 1);
invpi(pi) = (1:cfg.K_info).';

[results.BER_th, results.SER_th] = analysis_stage('theory', cfg);
results.BER_pre = zeros(numel(cfg.snr_db), 1);
results.BER_post = zeros(numel(cfg.snr_db), 1);
results.SER_pre = zeros(numel(cfg.snr_db), 1);
results.SER_post = zeros(numel(cfg.snr_db), 1);

fprintf('OFDM: %d subcarriers, CP=%d, nTx=nRx=2, L=%d\n', cfg.N, cfg.CP, cfg.L);
fprintf('Turbo: K=%d, Ncoded=%d, Ns_used=%d/%d QAM symbols\n\n', ...
    cfg.K_info, cfg.Ncoded, cfg.Ns_used, cfg.sym_per_ofdm);
for iSNR = 1:numel(cfg.snr_db)
    snrDb = cfg.snr_db(iSNR);
    snrLin = 10^(snrDb / 10);
    bitErrPre = 0; bitErrPost = 0; bitTot = 0;
    symErrPre = 0; symErrPost = 0;
    for frame = 1:cfg.N_sym
        s = simulate_frame(cfg, pi, invpi, snrLin);
        bitErrPre = bitErrPre + s.bit_err_pre;
        bitErrPost = bitErrPost + s.bit_err_post;
        bitTot = bitTot + s.bit_tot;
        symErrPre = symErrPre + s.sym_err_pre;
        symErrPost = symErrPost + s.sym_err_post;
    end
    symTot = cfg.N_sym * cfg.Ns_used;
    results.BER_pre(iSNR) = bitErrPre / bitTot;
    results.BER_post(iSNR) = bitErrPost / bitTot;
    results.SER_pre(iSNR) = symErrPre / symTot;
    results.SER_post(iSNR) = symErrPost / symTot;
    fprintf('SNR=%2d dB | BER_pre=%.3e BER_post=%.3e | SER_pre=%.3e SER_post=%.3e\n', ...
        snrDb, results.BER_pre(iSNR), results.BER_post(iSNR), ...
        results.SER_pre(iSNR), results.SER_post(iSNR));
end
end
