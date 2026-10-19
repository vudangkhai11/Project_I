function varargout = qam16_stage(action, varargin)
%QAM16_STAGE Modulate, hard-demodulate, or compute soft LLRs for 16-QAM.
switch lower(action)
    case 'mod'
        varargout{1} = qam16_mod(varargin{1});
    case 'hard'
        varargout{1} = qam16_hard(varargin{1});
    case 'llr'
        [varargout{1}, varargout{2}] = qam16_demod_llr(varargin{1}, varargin{2});
    otherwise
        error('qam16_stage:UnknownAction', 'Action must be mod, hard, or llr.');
end
end

function syms = qam16_mod(bits)
% bits: column vector length multiple of 4
    bits = bits(:);
    if mod(length(bits),4)~=0
        error('qam16_mod: bits length must be multiple of 4');
    end
    b = reshape(bits,4,[]).'; % Ns x 4
    b3=b(:,1); b2=b(:,2); b1=b(:,3); b0=b(:,4);

    Ns = size(b,1);
    I = zeros(Ns,1); Q = zeros(Ns,1);

    I(~b3 & ~b2) =  3;
    I(~b3 &  b2) =  1;
    I( b3 &  b2) = -1;
    I( b3 & ~b2) = -3;

    Q(~b1 & ~b0) =  3;
    Q(~b1 &  b0) =  1;
    Q( b1 &  b0) = -1;
    Q( b1 & ~b0) = -3;

    syms = (I + 1j*Q)/sqrt(10); % unit avg power
end


function [bits, llr_vec] = qam16_demod_llr(syms, noiseVarSym)
% Max-log LLR per bit for Gray 16-QAM
% noiseVarSym: scalar or vector (Ns x 1) variance at symbol (complex)
    persistent const_points bit_labels;
    if isempty(const_points)
        bit_labels = my_de2bi(0:15,4);        % 16 x 4
        all_bits = bit_labels.'; all_bits = all_bits(:);
        const_points = qam16_mod(all_bits);   % 16 x 1
    end

    syms = syms(:);
    Ns = length(syms);

    if isscalar(noiseVarSym)
        noiseVarSym = noiseVarSym*ones(Ns,1);
    else
        noiseVarSym = noiseVarSym(:);
        if length(noiseVarSym)~=Ns
            error('qam16_demod_llr: noiseVarSym must be scalar or Ns-length vector');
        end
    end

    % distances
    d2 = zeros(Ns,16);
    for m = 1:16
        d2(:,m) = abs(syms - const_points(m)).^2;
    end

    llr = zeros(Ns,4);
    bits_hard = zeros(Ns,4);

    for j = 1:4
        mask0 = (bit_labels(:,j)==0);
        mask1 = ~mask0;

        d0 = min(d2(:,mask0),[],2);
        d1 = min(d2(:,mask1),[],2);

        llr(:,j) = (d1 - d0) ./ noiseVarSym;  % log(P0/P1) up to const
        bits_hard(:,j) = (llr(:,j) < 0);
    end

    bits    = reshape(bits_hard.',[],1);
    llr_vec = reshape(llr.',[],1);
end



function syms_hd = qam16_hard(syms)
    persistent const_points;
    if isempty(const_points)
        bit_labels = my_de2bi(0:15,4);
        all_bits = bit_labels.'; all_bits = all_bits(:);
        const_points = qam16_mod(all_bits);
    end
    syms = syms(:);
    Ns = length(syms);
    d2 = zeros(Ns,16);
    for m = 1:16
        d2(:,m) = abs(syms - const_points(m)).^2;
    end
    [~,idx] = min(d2,[],2);
    syms_hd = const_points(idx);
end



function B = my_de2bi(vec, n)
% left-msb
    vec = vec(:);
    N = length(vec);
    B = zeros(N,n);
    for i = 1:n
        B(:,i) = mod(floor(vec / 2^(n-i)), 2);
    end
end


