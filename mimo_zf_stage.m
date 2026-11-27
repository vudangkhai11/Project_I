function varargout = mimo_zf_stage(action, varargin)
%MIMO_ZF_STAGE Per-subcarrier ZF or MMSE detection.
switch lower(action)
    case 'detect'
        rxFreq = varargin{1};
        Hfreq  = varargin{2};
        cfg    = varargin{3};

        eqType = 'zf';
        snrLin = 10;
        if nargin >= 4, eqType = lower(varargin{4}); end
        if nargin >= 5, snrLin = varargin{5}; end

        rxSyms   = zeros(cfg.N, cfg.nTx);
        noiseEnh = zeros(cfg.N, cfg.nTx);

        for k = 1:cfg.N
            Hk = squeeze(Hfreq(k, :, :));

            if strcmp(eqType, 'mmse')
                % Can bang MMSE: W = inv(H'*H + (1/SNR)*I) * H'
                G = inv(Hk' * Hk + (1 / snrLin) * eye(cfg.nTx));
                W = G * Hk';
                WH = W * Hk;
                for tx = 1:cfg.nTx
                    mu = real(WH(tx, tx));
                    rxSyms(k, tx) = (W(tx, :) * rxFreq(k, :).') / mu;
                    % Tinh du ca nhieu Gaussian va can nhieu du giua cac luong
                    interf = max(0, sum(abs(WH(tx, :)).^2) - mu^2);
                    noiseEnh(k, tx) = (norm(W(tx, :))^2 + snrLin * interf) / (mu^2);
                end
            else
                % Can bang ZF truyen thong
                G = (Hk' * Hk) \ eye(cfg.nTx);
                W = G * Hk';
                rxSyms(k, :) = (W * rxFreq(k, :).').';
                noiseEnh(k, :) = real(diag(G)).';
            end
        end
        varargout{1} = rxSyms;
        varargout{2} = noiseEnh;
    otherwise
        error('mimo_zf_stage:UnknownAction', 'Action must be detect.');
end
end
