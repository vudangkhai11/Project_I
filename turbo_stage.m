function varargout = turbo_stage(action, varargin)
%TURBO_STAGE Encode or decode the rate~1/3 RSC Turbo code.
switch lower(action)
    case 'encode'
        varargout{1} = turbo_encode_rsc(varargin{1}, varargin{2});
    case 'decode'
        varargout{1} = turbo_decode_maxlog(varargin{1}, varargin{2}, varargin{3}, ...
            varargin{4}, varargin{5}, varargin{6});
    otherwise
        error('turbo_stage:UnknownAction', 'Action must be encode or decode.');
end
end

function coded = turbo_encode_rsc(u, pi)
% Turbo rate~1/3: [systematic; parity1; parity2]
    u = u(:);
    p1 = rsc_parity_13_15(u);
    u2 = u(pi);
    p2 = rsc_parity_13_15(u2);
    coded = [u; p1; p2];
end



function uhat = turbo_decode_maxlog(Lsys, Lp1, Lp2, pi, invpi, nIter)
% Max-Log-MAP turbo decoder for RSC(13,15), no termination (simplified)
    K = length(Lsys);
    Lsys = Lsys(:); Lp1 = Lp1(:); Lp2 = Lp2(:);

    Lsys_i = Lsys(pi);

    La1 = zeros(K,1);
    Le1 = zeros(K,1);

    for it = 1:nIter
        % Decoder 1
        [~, Le1] = rsc_bcjr_maxlog(Lsys, Lp1, La1);

        % Interleave extrinsic -> a priori for decoder 2
        La2 = Le1(pi);

        % Decoder 2 (on interleaved sequence)
        [~, Le2_i] = rsc_bcjr_maxlog(Lsys_i, Lp2, La2);

        % Deinterleave extrinsic back
        Le2 = Le2_i(invpi);

        % Feedback as new a priori
        La1 = Le2;
    end

    % Final LLR (common practice)
    L_final = Lsys + La1 + Le1;
    uhat = (L_final < 0);
end



function p = rsc_parity_13_15(u)
% RSC(13,15) octal, memory=3 (8 states), no tail bits
% feedback poly 13(oct)=1011 => taps r1,r3
% feedforward 15(oct)=1101 => taps r2,r3
    u = u(:);
    K = length(u);
    p = zeros(K,1);

    r1=0; r2=0; r3=0; % shift register
    for k = 1:K
        d = xor(u(k), xor(r1, r3));        % feedback
        p(k) = xor(d, xor(r2, r3));        % parity
        % shift
        r3 = r2; r2 = r1; r1 = d;
    end
end


function [Lpost, Lext] = rsc_bcjr_maxlog(Lsys, Lpar, Lapri)
% Max-Log-MAP BCJR for RSC(13,15), 8-state, no termination
    Lsys = Lsys(:); Lpar = Lpar(:); Lapri = Lapri(:);
    T = length(Lsys);
    nStates = 8;

    [nextState, parityBit] = rsc_trellis_13_15();

    % alpha/beta in log domain
    alpha = -inf(T+1, nStates);
    beta  = zeros(T+1, nStates);  % no termination: beta(T+1,:) = 0
    alpha(1,1) = 0;               % start from state 0

    % branch metrics gamma(t,s,u)
    gamma = -inf(T, nStates, 2);
    for t = 1:T
        for s = 1:nStates
            for u = 0:1
                p = parityBit(s,u+1);
                xu = 1 - 2*u;     % 0->+1, 1->-1
                xp = 1 - 2*p;
                gamma(t,s,u+1) = 0.5*(xu*(Lsys(t)+Lapri(t)) + xp*Lpar(t));
            end
        end
    end

    % forward
    for t = 1:T
        for s = 1:nStates
            a = alpha(t,s);
            if isinf(a), continue; end
            for u = 0:1
                sp = nextState(s,u+1) + 1;
                alpha(t+1,sp) = max(alpha(t+1,sp), a + gamma(t,s,u+1));
            end
        end
    end

    % backward
    for t = T:-1:1
        for s = 1:nStates
            sp0 = nextState(s,1)+1;
            sp1 = nextState(s,2)+1;
            b0 = beta(t+1,sp0) + gamma(t,s,1);
            b1 = beta(t+1,sp1) + gamma(t,s,2);
            beta(t,s) = max(b0,b1);
        end
    end

    % LLR computation
    Lpost = zeros(T,1);
    for t = 1:T
        m0 = -inf; m1 = -inf;
        for s = 1:nStates
            for u = 0:1
                sp = nextState(s,u+1)+1;
                metric = alpha(t,s) + gamma(t,s,u+1) + beta(t+1,sp);
                if u==0
                    m0 = max(m0, metric);
                else
                    m1 = max(m1, metric);
                end
            end
        end
        Lpost(t) = m0 - m1; % log P(u=0)/P(u=1)
    end

    Lext = Lpost - Lsys - Lapri;
end



function [nextState, parityBit] = rsc_trellis_13_15()
% state s is 0..7 with bits [r1 r2 r3] (r1=1-delay, r3=3-delay)
    nStates = 8;
    nextState = zeros(nStates,2);
    parityBit = zeros(nStates,2);

    for s = 0:nStates-1
        r1 = bitget(s,3);
        r2 = bitget(s,2);
        r3 = bitget(s,1);

        for u = 0:1
            d = xor(u, xor(r1, r3));      % feedback 13
            p = xor(d, xor(r2, r3));      % feedforward 15

            nr1 = d; nr2 = r1; nr3 = r2;  % shift
            sp = nr1*4 + nr2*2 + nr3;

            nextState(s+1,u+1) = sp;
            parityBit(s+1,u+1) = p;
        end
    end
end

