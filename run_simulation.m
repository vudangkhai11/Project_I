function results = run_simulation(cfg)
%RUN_SIMULATION Run the SNR sweep and aggregate frame error counters.
rng(cfg.seed);
pi = randperm(cfg.K_info).';
invpi = zeros(cfg.K_info, 1);
invpi(pi) = (1:cfg.K_info).';

results.BER_th = analysis_stage('theory', cfg);
results.BER_post = zeros(numel(cfg.snr_db), numel(cfg.iter_list));

fprintf('OFDM: %d subcarriers, CP=%d, nTx=nRx=2, L=%d\n', cfg.N, cfg.CP, cfg.L);
fprintf('Turbo: K=%d, Ncoded=%d, Ns_used=%d/%d QAM symbols\n\n', ...
    cfg.K_info, cfg.Ncoded, cfg.Ns_used, cfg.sym_per_ofdm);
for iSNR = 1:numel(cfg.snr_db)
    snrDb = cfg.snr_db(iSNR);
    snrLin = 10^(snrDb / 10);
    bitErrPost = zeros(numel(cfg.iter_list), 1);
    bitTot = 0;
    for frame = 1:cfg.N_sym
        s = simulate_frame(cfg, pi, invpi, snrLin);
        bitErrPost = bitErrPost + s.bit_err_post;
        bitTot = bitTot + s.bit_tot;
    end
    results.BER_post(iSNR, :) = (bitErrPost / bitTot).';
    fprintf('SNR=%2d dB | BER_uncoded_ZF_theory=%.3e', ...
        snrDb, results.BER_th(iSNR));
    for iIter = 1:numel(cfg.iter_list)
        fprintf(' | BER_Turbo_%dit=%.3e', ...
            cfg.iter_list(iIter), results.BER_post(iSNR, iIter));
    end
    fprintf('\n');
end
end
