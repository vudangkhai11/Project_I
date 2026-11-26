function varargout = qam16_stage(action, varargin)
% Thuc chat da duoc nang cap len 64-QAM (Gray mapping, 6 bit/symbol)
switch lower(action)
    case 'mod'
        varargout{1} = qam64_mod(varargin{1});
    case 'llr'
        [varargout{1}, varargout{2}] = qam64_demod_llr(varargin{1}, varargin{2});
    otherwise
        error('qam16_stage:UnknownAction', 'Action must be mod or llr.');
end
end

function syms = qam64_mod(bits)
bits = bits(:);
if mod(length(bits), 6) ~= 0
    error('bits length must be multiple of 6');
end
b = reshape(bits, 6, []).'; % Ns x 6

map = [7, 5, 3, 1, -1, -3, -5, -7];
gray_idx = [0 1 3 2 6 7 5 4];
[~, gray_to_level] = sort(gray_idx);

decI = b(:,1)*4 + b(:,2)*2 + b(:,3);
decQ = b(:,4)*4 + b(:,5)*2 + b(:,6);

I = map(gray_to_level(decI + 1)).';
Q = map(gray_to_level(decQ + 1)).';

syms = (I + 1j*Q) / sqrt(42); % Chuan hoa cong suat 64-QAM
end

function [bits, llr_vec] = qam64_demod_llr(syms, noiseVarSym)
persistent const_points bit_labels;
if isempty(const_points)
    bit_labels = my_de2bi(0:63, 6);
    all_bits = bit_labels.'; all_bits = all_bits(:);
    const_points = qam64_mod(all_bits);
end

syms = syms(:);
Ns = length(syms);
if isscalar(noiseVarSym)
    noiseVarSym = noiseVarSym * ones(Ns, 1);
else
    noiseVarSym = noiseVarSym(:);
end

% Tinh khoang cach toi 64 diem chom sao
d2 = abs(syms - const_points.').^2;

llr = zeros(Ns, 6);
bits_hard = zeros(Ns, 6);

for j = 1:6
    mask0 = (bit_labels(:, j) == 0);
    mask1 = ~mask0;

    d0 = min(d2(:, mask0), [], 2);
    d1 = min(d2(:, mask1), [], 2);

    llr(:, j) = (d1 - d0) ./ noiseVarSym;
    bits_hard(:, j) = (llr(:, j) < 0);
end

bits = reshape(bits_hard.', [], 1);
llr_vec = reshape(llr.', [], 1);
end

function B = my_de2bi(vec, n)
vec = vec(:);
N = length(vec);
B = zeros(N, n);
for i = 1:n
    B(:, i) = mod(floor(vec / 2^(n-i)), 2);
end
end