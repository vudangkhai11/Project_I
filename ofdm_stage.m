function out = ofdm_stage(action, in, cfg)
%OFDM_STAGE Perform OFDM IFFT/CP insertion or CP removal/FFT.
switch lower(action)
    case 'mod'
        time = ifft(in, cfg.N, 1);
        out = [time(end-cfg.CP+1:end, :); time];
    case 'demod'
        withoutCp = in(cfg.CP+1:end, :);
        out = fft(withoutCp, cfg.N, 1);
    otherwise
        error('ofdm_stage:UnknownAction', 'Action must be mod or demod.');
end
end
