function cfg = config_params()
%CONFIG_PARAMS Central simulation settings.
cfg.N = 64;
cfg.CP = 16;
cfg.N_sym = 500;
cfg.snr_db = 5:1:15;
cfg.nTx = 2;
cfg.nRx = 2;
cfg.L = 10;
cfg.M = 64;
cfg.bits_per_sym = log2(cfg.M);
cfg.N_ofdm = 4;
cfg.sym_per_ofdm = cfg.N * cfg.nTx;
cfg.bits_per_ofdm = cfg.sym_per_ofdm * cfg.bits_per_sym;
cfg.bits_per_frame = cfg.bits_per_ofdm * cfg.N_ofdm;
cfg.K_info = 1024;
if cfg.CP > cfg.N || cfg.L > cfg.CP
    error('Require CP <= N and channel taps L <= CP.');
end
cfg.Ncoded = 3 * cfg.K_info;
if mod(cfg.Ncoded, cfg.bits_per_sym) ~= 0
    error('Ncoded must be a multiple of bits_per_sym.');
end
cfg.Ns_used = cfg.Ncoded / cfg.bits_per_sym;
if cfg.Ncoded > cfg.bits_per_frame
    error('Ncoded > bits_per_frame: reduce K_info or increase N_ofdm.');
end
cfg.bits_pad = cfg.bits_per_frame - cfg.Ncoded;
cfg.iter_list = [2 6 8];
cfg.Ntheory = 200000;
cfg.seed = 2026;
end

