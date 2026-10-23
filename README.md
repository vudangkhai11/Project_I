# Đồ án I: Mô phỏng hệ thống 2x2 MIMO-OFDM sử dụng mã Turbo

## 1. Mục tiêu

Mục tiêu của đồ án là khảo sát hiệu quả của mã Turbo trong hệ thống 2x2 MIMO-OFDM. Hiệu năng hệ thống được đánh giá qua BER sau giải mã so với hệ thống không mã hóa ở các mức SNR khác nhau.

## 2. Sơ đồ hệ thống

Sơ đồ khối tổng quát của hệ thống MIMO-OFDM được trình bày dưới đây.

![Sơ đồ khối hệ thống MIMO-OFDM](docs/images/turbo.jpg)

*Hình 1. Sơ đồ khối hệ thống MIMO-OFDM 2×2 sử dụng điều chế 16-QAM và mã Turbo.*

## 3. Mô hình hệ thống

Hệ thống mô phỏng sử dụng hai anten phát và hai anten thu (MIMO 2×2), kết hợp với OFDM gồm 64 sóng mang con. Dữ liệu được điều chế 16-QAM, biến đổi IFFT và gắn tiền tố chu kỳ (CP) dài 16 mẫu trước khi truyền. Kênh giữa mỗi cặp anten phát-thu là kênh Rayleigh đa đường gồm 10 tap độc lập, có công suất trung bình chuẩn hóa; nhiễu cộng Gaussian trắng (AWGN) phức được thêm vào tín hiệu thu theo mức SNR đang khảo sát.

Kênh được giữ cố định trong một frame và tạo lại độc lập giữa các frame. CP dài hơn số tap kênh, nên sau khi bỏ CP và thực hiện FFT, có thể mô hình hóa tín hiệu riêng trên từng sóng mang con. Trên sóng mang con thứ $k$, mô hình tín hiệu là $\mathbf{y}[k]=\mathbf{H}[k]\mathbf{x}[k]+\mathbf{n}[k]$, trong đó $\mathbf{x}[k]$ là vector tín hiệu phát, $\mathbf{H}[k]$ là ma trận kênh, và $\mathbf{n}[k]$ là vector nhiễu.

Trong chương trình, SNR được đặt theo tỉ số công suất tín hiệu mẫu ở đầu vào kênh trên công suất AWGN phức ở đầu vào kênh: $\mathrm{SNR}=P_{signal}/P_{noise}$. Giá trị dB được đổi sang tuyến tính trước khi tạo nhiễu. Sau FFT và cân bằng ZF, phương sai nhiễu được tính theo từng luồng và từng sóng mang con để tạo LLR cho giải mã mềm. Đường BER tham chiếu dùng cùng quy ước SNR đầu vào; $\gamma$ trong xấp xỉ BER 16-QAM là SNR ký hiệu sau ZF.

Bộ thu được giả định biết chính xác ma trận kênh (CSI hoàn hảo) và dùng cân bằng Zero-Forcing (ZF) trên từng sóng mang con để ước lượng tín hiệu phát: $\hat{\mathbf{x}}[k]=(\mathbf{H}^{H}[k]\mathbf{H}[k])^{-1}\mathbf{H}^{H}[k]\mathbf{y}[k]$. Tín hiệu ước lượng sau đó được giải điều chế mềm và đưa vào bộ giải mã Turbo.

## 4. Mã hóa và giải mã Turbo

### 4.1. Mã hóa Turbo

Bộ mã hóa gồm hai bộ mã tích chập đệ quy hệ thống (RSC), dùng đa thức sinh $(13,15)_8$ và bộ nhớ 3. Mỗi bộ cập nhật thanh ghi trạng thái và tính bit parity bằng các phép XOR trên bit. Bộ thứ nhất xử lý chuỗi bit thông tin theo thứ tự ban đầu; bộ thứ hai xử lý cùng chuỗi sau khi đan xen.

Đầu ra gồm chuỗi bit thông tin gốc (bit hệ thống) và hai chuỗi parity, nên tốc độ mã xấp xỉ 1/3. Với 160 bit thông tin mỗi frame, bộ mã tạo 480 bit mã hóa. Sau đó chương trình thêm 32 bit 0 để lấp đầy dung lượng 512 bit của một symbol OFDM trên hai anten. Padding chỉ dùng để lấp frame, không đi qua bộ mã Turbo. Bộ mã cũng không thêm tail bits để đưa trạng thái trellis về trạng thái kết thúc.

### 4.2. Giải mã Turbo

#### 4.2.1. Quy ước LLR và các tín hiệu vào

Giải điều chế mềm tạo một LLR cho mỗi bit mã hóa. Trong mã nguồn, quy ước dấu là

$$L(b)=\ln\frac{P(b=0\mid y)}{P(b=1\mid y)}.$$

Vì vậy, LLR dương nghiêng về bit 0, LLR âm nghiêng về bit 1, và độ lớn $|L|$ thể hiện mức độ tin cậy. Quy ước này được dùng xuyên suốt `rsc_bcjr_maxlog`: quyết định cứng là `L < 0` cho bit 1.

Với $K=160$, chuỗi phát gồm ba phần dài $K$: bit hệ thống $u_k$, parity của encoder thứ nhất $p^{(1)}_k$, và parity của encoder thứ hai $p^{(2)}_k$. Bộ thu đưa ba chuỗi LLR tương ứng vào decoder:

$$L_{sys,k},\qquad L_{p1,k},\qquad L_{p2,k}.$$

Decoder thứ nhất xử lý thứ tự ban đầu. Decoder thứ hai xử lý thứ tự đã đan xen bởi hoán vị `pi`. Bit hệ thống cũng được đan xen cho decoder thứ hai: `Lsys_i = Lsys(pi)`. `invpi` là hoán vị nghịch đảo dùng để đưa thông tin trả về đúng thứ tự ban đầu.

#### 4.2.2. Trellis RSC và metric nhánh

Mỗi encoder RSC có bộ nhớ 3 nên có $2^3=8$ trạng thái. Trong `rsc_trellis_13_15`, trạng thái được biểu diễn bằng ba bit thanh ghi $(r_1,r_2,r_3)$. Với bit vào $u\in\{0,1\}$, cập nhật encoder là

$$d=u\oplus r_1\oplus r_3,\qquad p=d\oplus r_2\oplus r_3,$$

$$ (r_1',r_2',r_3')=(d,r_1,r_2). $$

Ở đây $d$ là bit đưa vào thanh ghi sau hồi tiếp, $p$ là bit parity, và $\oplus$ là XOR. Các phương trình này xác định duy nhất trạng thái kế tiếp $s'$ và parity trên mỗi nhánh trellis. Chúng tương ứng với quy ước đa thức $(13,15)_8$ được dùng trong encoder của project.

Để cộng xác suất trong miền log, decoder biểu diễn bit 0 bằng $+1$ và bit 1 bằng $-1$: $x(b)=1-2b$. Với nhánh tại thời điểm $k$, từ trạng thái $s$ nhận bit vào $u$ và parity dự đoán $p(s,u)$, metric nhánh mà mã tính là

$$\gamma_k(s,u)=\frac{1}{2}\left[x(u)(L_{sys,k}+L_{a,k})+x(p(s,u))L_{par,k}\right].$$

Ở đây $L_{a,k}$ là LLR tiên nghiệm (a priori) từ decoder còn lại; $L_{par,k}$ là LLR quan sát của parity. Metric lớn hơn nghĩa là nhánh phù hợp hơn với LLR nhận được. Hệ số $1/2$ giữ đúng dạng log-likelihood với quy ước LLR nêu trên; thành phần hằng chung cho mọi nhánh có thể bỏ vì nó không làm đổi quyết định.

#### 4.2.3. Hai lượt quy hoạch động BCJR

BCJR không liệt kê toàn bộ $2^K$ chuỗi bit. Thay vào đó, nó tính metric tốt nhất đi tới và đi khỏi mỗi trạng thái tại mỗi thời điểm. Trong triển khai này phép cộng xác suất được thay bằng phép lấy cực đại, tức xấp xỉ Max-Log-MAP:

$$\max(a,b)\approx\ln(e^a+e^b).$$

**Lượt tiến (forward):** $\alpha_k(s)$ là metric tốt nhất của mọi đường đi từ đầu chuỗi đến trạng thái $s$ ở thời điểm $k$. Mã khởi tạo $\alpha_0(0)=0$ và $\alpha_0(s)=-\infty$ cho các trạng thái khác, vì encoder bắt đầu ở trạng thái 0. Sau đó cập nhật

$$\alpha_k(s')=\max_{s,u:\,next(s,u)=s'}\left[\alpha_{k-1}(s)+\gamma_k(s,u)\right].$$

Đây là phép cộng metric nhánh vào mọi đường đi có thể đến $s'$, rồi chỉ giữ đường tốt nhất.

**Lượt lùi (backward):** $\beta_k(s)$ là metric tốt nhất của phần đường đi còn lại từ trạng thái $s$ ở thời điểm $k$ đến hết chuỗi. Vì encoder không phát tail bits và mã không ép trạng thái cuối về 0, chương trình khởi tạo $\beta_K(s)=0$ cho cả 8 trạng thái. Đệ quy ngược là

$$\beta_{k-1}(s)=\max_{u\in\{0,1\}}\left[\gamma_k(s,u)+\beta_k(next(s,u))\right].$$

Khởi tạo này có nghĩa là mọi trạng thái cuối đều được phép như nhau; nó không khẳng định trạng thái encoder thật sự kết thúc ở 0.

#### 4.2.4. LLR hậu nghiệm và thông tin ngoại lai

Với mỗi thời điểm $k$, decoder tìm metric tốt nhất của mọi đường đi có bit vào bằng 0, rồi làm tương tự cho bit vào bằng 1. Metric của một nhánh hoàn chỉnh gồm đường đi trước nhánh, chính nhánh đó và đường đi sau nhánh:

$$M_k(u)=\max_{s}\left[\alpha_{k-1}(s)+\gamma_k(s,u)+\beta_k(next(s,u))\right].$$

LLR hậu nghiệm (posterior) theo quy ước dấu của project là

$$L_{post,k}=M_k(0)-M_k(1).$$

Nếu $L_{post,k}>0$, các quan sát và ràng buộc trellis ủng hộ bit 0 hơn; nếu âm, chúng ủng hộ bit 1 hơn. Max-Log-MAP dùng hiệu hai metric cực đại thay vì log-tổng-xác-suất chính xác, do đó là một xấp xỉ MAP.

LLR hậu nghiệm đã chứa cả thông tin hệ thống và tiên nghiệm đầu vào. Để tránh gửi nguyên thông tin cũ quay lại decoder kia, mã tạo thông tin ngoại lai (extrinsic) bằng

$$L_{e,k}=L_{post,k}-L_{sys,k}-L_{a,k}.$$

Thông tin ngoại lai là phần mới decoder rút ra từ parity và ràng buộc trellis sau khi loại hai nguồn thông tin đã biết. Công thức tách này là lý do dấu LLR, cách dựng metric nhánh và phép quyết định phải thống nhất.

#### 4.2.5. Trao đổi giữa hai decoder và một vòng lặp

Mã khởi tạo tiên nghiệm cho decoder 1 bằng 0: `La1 = zeros(K,1)`. Mỗi **vòng lặp Turbo** trong `turbo_decode_maxlog` gồm đủ hai lần chạy BCJR:

1. Decoder 1 chạy trên $(L_{sys},L_{p1},L_{a1})$ theo thứ tự ban đầu và tạo $L_{e1}$.
2. Đan xen $L_{e1}$ bằng `La2 = Le1(pi)` để làm tiên nghiệm cho decoder 2.
3. Decoder 2 chạy trên $(L_{sys}(pi),L_{p2},L_{a2})$ theo thứ tự đã đan xen và tạo $L_{e2,i}$.
4. Giải đan xen: `Le2 = Le2_i(invpi)`. Kết quả này trở thành tiên nghiệm `La1` ở vòng tiếp theo.

Sơ đồ luồng thông tin là

```text
Decoder 1: Lsys, Lp1, La1  -> Le1
                                  | interleave
                                  v
Decoder 2: Lsys(pi), Lp2, La2 -> Le2_i
                                  | deinterleave
                                  v
                              La1 vòng sau
```

Hai decoder không gửi lại toàn bộ LLR hậu nghiệm; chúng trao đổi phần ngoại lai để thông tin hệ thống không bị đếm lặp như thể là quan sát mới. Tăng số vòng cho decoder thêm cơ hội dùng parity của nhánh kia, nhưng cũng tăng thời gian tính toán.

#### 4.2.6. Quyết định bit và ý nghĩa số vòng

Sau vòng lặp cuối, mã hiện tại kết hợp LLR thành phần hệ thống với thông tin trao đổi và thông tin ngoại lai của decoder 1:

$$L_{final}=L_{sys}+L_{a1}+L_{e1},\qquad \hat{u}_k=\begin{cases}0,&L_{final,k}\ge 0,\\1,&L_{final,k}<0.\end{cases}$$

Trong MATLAB điều này được viết là `uhat = (L_final < 0)`. Số `nIter` là số vòng trao đổi Turbo, mỗi vòng gồm decoder 1 và decoder 2 chạy một lần; nó không phải số lần chạy tổng cộng của một decoder đơn lẻ. Project hiện cấu hình so sánh 2, 6 và 8 vòng trong `config_params.m`. Hàm decoder chạy lại thuật toán từ trạng thái tiên nghiệm ban đầu khi được gọi riêng với từng số vòng; nó không tự động lưu checkpoint giữa các lần gọi.

Các chi tiết trên mô tả đúng implementation trong `turbo_stage.m`: Max-Log-MAP (không có hiệu chỉnh Log-MAP), trellis 8 trạng thái, trạng thái đầu xác định bằng 0, trạng thái cuối không ràng buộc, và không có tail bits. Vì vậy kết quả có thể khác decoder Toolbox dùng Log-MAP chính xác, quy ước interleaver/trellis khác, hoặc xử lý trạng thái kết thúc khác.

## 5. Tham số mô phỏng

Các giá trị mặc định được khai báo trong `config_params.m`.

| Tham số | Giá trị mặc định | Ý nghĩa |
|---|---:|---|
| Số anten phát, $n_{Tx}$ | 2 | Số luồng phát MIMO |
| Số anten thu, $n_{Rx}$ | 2 | Số luồng thu MIMO |
| Số sóng mang con, $N$ | 64 | Kích thước FFT/IFFT của OFDM |
| Độ dài CP | 16 mẫu | Tiền tố chu kỳ cho mỗi symbol OFDM |
| Số tap kênh, $L$ | 10 | Số tap của kênh Rayleigh đa đường |
| Điều chế, $M$ | 16 | 16-QAM, tương đương 4 bit trên mỗi symbol |
| Bit thông tin mỗi frame, $K_{info}$ | 160 | Số bit đầu vào bộ mã Turbo |
| Số vòng giải mã Turbo | 2, 6, 8 | Các số vòng được so sánh |
| Số frame mỗi mức SNR | 200 | Số frame dùng để tính BER mô phỏng |
| Dải SNR | 0:2:20 dB | Các mức SNR từ 0 đến 20 dB, bước 2 dB |
| Số mẫu kênh tham chiếu, $N_{theory}$ | 200.000 | Số mẫu dùng tính đường tham chiếu lý thuyết |
| Seed ngẫu nhiên | 2026 | Giúp tái lập chuỗi ngẫu nhiên của mô phỏng |

Mỗi symbol OFDM trên hai anten có sức chứa $64\times2\times4=512$ bit. Trong đó, 480 bit là đầu ra mã Turbo và 32 bit còn lại là padding. Chương trình kiểm tra các điều kiện kích thước như CP không dài hơn FFT, số tap kênh không vượt quá độ dài CP, và số bit mã hóa không vượt sức chứa symbol OFDM.

## 6. Phương pháp đánh giá

Chỉ số chính là BER sau giải mã Turbo. Với mỗi mức SNR, bộ thu so sánh các bit thông tin sau giải mã với các bit thông tin đã phát, rồi chia tổng số bit sai cho tổng số bit đã phát:

$$\mathrm{BER}_{post}=\frac{\text{số bit thông tin giải mã sai}}{\text{tổng số bit thông tin đã phát}}.$$

Mô phỏng chạy 200 frame tại mỗi mức SNR; mỗi frame có 160 bit thông tin, tương đương 32.000 bit được đánh giá cho một điểm SNR. BER sau giải mã được so sánh với đường tham chiếu lý thuyết của hệ thống 16-QAM không mã hóa dùng ZF trên kênh Rayleigh 2×2. Đường tham chiếu được tính bằng xấp xỉ lý thuyết và lấy trung bình trên 200.000 mẫu kênh.

Chương trình hiện ghi BER lý thuyết tham chiếu và BER sau giải mã Turbo cho từng số vòng lặp. Với 200 frame và 160 bit thông tin mỗi frame, mỗi điểm BER sau giải mã dựa trên 32.000 bit thông tin.

## 7. Cấu trúc chương trình

| File | Chức năng |
|---|---|
| `main.m` | Điểm bắt đầu: nạp cấu hình, chạy mô phỏng và vẽ biểu đồ. |
| `config_params.m` | Khai báo tham số mặc định và kiểm tra các điều kiện kích thước. |
| `run_simulation.m` | Quét các mức SNR, chạy nhiều frame và tổng hợp BER theo số vòng Turbo. |
| `simulate_frame.m` | Thực hiện một frame từ sinh bit, truyền qua kênh, thu nhận đến giải mã và đếm lỗi. |
| `turbo_stage.m` | Mã hóa Turbo và giải mã lặp Max-Log-MAP BCJR. |
| `qam16_stage.m` | Điều chế 16-QAM, quyết định cứng và tính LLR mềm. |
| `ofdm_stage.m` | Thực hiện IFFT/FFT và thêm/bỏ tiền tố chu kỳ. |
| `channel_stage.m` | Mô phỏng kênh Rayleigh đa đường và nhiễu AWGN. |
| `mimo_zf_stage.m` | Cân bằng Zero-Forcing trên từng sóng mang con. |
| `analysis_stage.m` | Tính đường BER tham chiếu và vẽ biểu đồ BER. |
| `docs/images/turbo.jpg` | Sơ đồ khối hệ thống dùng trong README. |
| `docs/images/ket_qua.png` | Biểu đồ BER với các mức lặp Turbo. |

Luồng chạy bắt đầu từ `main.m`, sau đó `run_simulation.m` gọi `simulate_frame.m` cho từng frame và mức SNR. Các khối điều chế, OFDM, kênh, cân bằng và Turbo được thực hiện bởi các file stage tương ứng.

## 8. Cách chạy mô phỏng

### MATLAB Desktop

1. Mở MATLAB và đặt thư mục `github_modular` làm Current Folder.
2. Mở `main.m` hoặc nhập `main` vào Command Window.
3. Chờ chương trình chạy hết các mức SNR. BER tham chiếu và BER sau giải mã với 2, 6, 8 vòng lặp sẽ được in trong Command Window; sau đó chương trình mở biểu đồ BER.

### MATLAB Online

1. Tải thư mục project lên MATLAB Drive.
2. Mở thư mục project trong MATLAB Online để đặt nó làm thư mục hiện tại.
3. Mở `main.m` và nhấn **Run**, hoặc nhập `main` vào Command Window.

Giữ các file `.m` cùng thư mục để MATLAB tìm thấy các hàm mô phỏng.

## 9. Kết quả

Biểu đồ dưới đây so sánh BER tham chiếu của ZF không mã hóa với BER sau giải mã Turbo tại 2, 6 và 8 vòng lặp.

![Kết quả BER theo SNR](docs/images/ket_qua.png)
