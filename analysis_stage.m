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
        for iSNR = 1:numel(cfg.snr_db)
            snrLin = 10^(cfg.snr_db(iSNR) / 10);
            gamma = snrLin ./ diagInv;
            Q = qfunc_local(sqrt(gamma / 5));
            BER(iSNR) = mean((3/4) * Q, 'all');
        end
        varargout{1} = BER;
    case 'plot'
        results = varargin{1};
        cfg = varargin{2};
        figure;
        semilogy(cfg.snr_db, results.BER_th, 'k--', 'LineWidth', 2); hold on;
        styles = {'o-', 's-', 'd-'};
        for iIter = 1:numel(cfg.iter_list)
            semilogy(cfg.snr_db, results.BER_post(:, iIter), styles{iIter}, ...
                'LineWidth', 2);
        end
        grid on; xlabel('SNR (dB)'); ylabel('BER');
        legendEntries = [{'Uncoded ZF theory'}, ...
            arrayfun(@(n) sprintf('Turbo decoder, %d iterations', n), ...
                cfg.iter_list, 'UniformOutput', false)];
        legend(legendEntries, 'Location', 'southwest');
        title('BER: 2x2 MIMO-OFDM, 16-QAM, Rayleigh+AWGN');
    otherwise
        error('analysis_stage:UnknownAction', 'Action must be theory or plot.');
end
end

function y = qfunc_local(x)
y = 0.5 * erfc(x / sqrt(2));
end

