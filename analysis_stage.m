function varargout = analysis_stage(action, varargin)
%ANALYSIS_STAGE Compute the ZF theory reference or plot BER/SER results.
switch lower(action)
    case 'theory'
        cfg = varargin{1};
        diagInv = zeros(cfg.Ntheory, cfg.nTx);
        for m = 1:cfg.Ntheory
            H = (randn(cfg.nRx, cfg.nTx) + 1j*randn(cfg.nRx, cfg.nTx)) / sqrt(2);
            G = (H' * H) \ eye(cfg.nTx);
            diagInv(m, :) = real(diag(G)).';
        end
        BER = zeros(numel(cfg.snr_db), 1);
        SER = zeros(numel(cfg.snr_db), 1);
        for iSNR = 1:numel(cfg.snr_db)
            snrLin = 10^(cfg.snr_db(iSNR) / 10);
            gamma = snrLin ./ diagInv;
            Q = qfunc_local(sqrt(gamma / 5));
            BER(iSNR) = mean((3/4) * Q, 'all');
            SER(iSNR) = mean(3*Q - (9/4)*(Q.^2), 'all');
        end
        varargout{1} = BER;
        varargout{2} = SER;
    case 'plot'
        results = varargin{1};
        cfg = varargin{2};
        figure;
        semilogy(cfg.snr_db, results.BER_pre, 'o-', 'LineWidth', 2); hold on;
        semilogy(cfg.snr_db, results.BER_post, 's-', 'LineWidth', 2);
        semilogy(cfg.snr_db, results.BER_th, 'k--', 'LineWidth', 2);
        grid on; xlabel('SNR (dB)'); ylabel('BER');
        legend('BER before decoding (systematic hard)', ...
            'BER after Turbo decoding (Max-Log-MAP)', ...
            'Uncoded BER theory (ZF 2x2 Rayleigh)', 'Location', 'southwest');
        title('BER: 2x2 MIMO-OFDM, 16-QAM, Rayleigh+AWGN');

        figure;
        semilogy(cfg.snr_db, results.SER_pre, 'o-', 'LineWidth', 2); hold on;
        semilogy(cfg.snr_db, results.SER_post, 's-', 'LineWidth', 2);
        semilogy(cfg.snr_db, results.SER_th, 'k--', 'LineWidth', 2);
        grid on; xlabel('SNR (dB)'); ylabel('SER');
        legend('SER before decoding (hard symbol)', ...
            'SER after decoding (decode->re-encode->remap)', ...
            'Uncoded SER theory (ZF 2x2 Rayleigh)', 'Location', 'southwest');
        title('SER: 2x2 MIMO-OFDM, 16-QAM, Rayleigh+AWGN');
    otherwise
        error('analysis_stage:UnknownAction', 'Action must be theory or plot.');
end
end

function y = qfunc_local(x)
y = 0.5 * erfc(x / sqrt(2));
end

