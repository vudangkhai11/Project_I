function [rxTime, Hfreq, noisePowerTime] = channel_stage(txTimeCp, snrLin, cfg)
%CHANNEL_STAGE Apply the original L-tap MIMO Rayleigh channel and AWGN.
Htime = (randn(cfg.L, cfg.nRx, cfg.nTx) + 1j*randn(cfg.L, cfg.nRx, cfg.nTx)) / sqrt(2*cfg.L);
Hfreq = fft(Htime, cfg.N, 1);
rxTime = zeros(cfg.N + cfg.CP, cfg.nRx);
for rx = 1:cfg.nRx
    for tx = 1:cfg.nTx
        h = squeeze(Htime(:, rx, tx));
        tmp = conv(txTimeCp(:, tx), h);
        rxTime(:, rx) = rxTime(:, rx) + tmp(1:cfg.N + cfg.CP);
    end
end
signalPower = mean(abs(txTimeCp(:)).^2);
noisePowerTime = signalPower / snrLin;
noise = sqrt(noisePowerTime / 2) * (randn(size(rxTime)) + 1j*randn(size(rxTime)));
rxTime = rxTime + noise;
end
