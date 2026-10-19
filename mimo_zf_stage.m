function varargout = mimo_zf_stage(action, varargin)
%MIMO_ZF_STAGE Apply per-subcarrier zero-forcing detection.
switch lower(action)
    case 'detect'
        rxFreq = varargin{1};
        Hfreq = varargin{2};
        cfg = varargin{3};
        rxSyms = zeros(cfg.N, cfg.nTx);
        noiseEnh = zeros(cfg.N, cfg.nTx);
        for k = 1:cfg.N
            Hk = squeeze(Hfreq(k, :, :));
            G = (Hk' * Hk) \ eye(cfg.nTx);
            W = G * Hk';
            rxSyms(k, :) = (W * rxFreq(k, :).').';
            noiseEnh(k, :) = real(diag(G)).';
        end
        varargout{1} = rxSyms;
        varargout{2} = noiseEnh;
    otherwise
        error('mimo_zf_stage:UnknownAction', 'Action must be detect.');
end
end

