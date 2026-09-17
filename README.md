# Thiết Kế Vi Xử Lý 9-Bit Tuỳ Biến (Custom 9-bit Processor in SystemVerilog)

## 📌 Tổng Quan Dự Án
Repository này chứa toàn bộ mã nguồn thiết kế RTL và kiểm thử chức năng (functional verification) cho **mô hình vi xử lý 9-bit kiến trúc tuỳ biến** bằng ngôn ngữ **SystemVerilog**. 

Dự án được phát triển theo từng giai đoạn nâng cấp: từ một Datapath cơ bản sử dụng Bus dùng chung (Single-Bus Accumulator Architecture) đến một vi xử lý hoàn chỉnh có khả năng chạy vòng lặp, tương tác với bộ nhớ ngoài (RAM/ROM) và các ngoại vi I/O (Đèn LED, LED 7-đoạn, Nút nhấn) thông qua kỹ thuật **Memory-Mapped I/O**, cùng các lệnh rẽ nhánh có điều kiện (Branching instructions).

Dự án được thiết kế, tổng hợp và mô phỏng trên công cụ **Intel Quartus Prime**, **ModelSim / QuestaSim** và **Vivado**.

---

## 🏗️ Kiến Trúc & Datapath

Vi xử lý được xây dựng dựa trên kiến trúc tập trung vào đường truyền dữ liệu nội bộ (Centralized Internal Bus) điều khiển bởi một Khối điều khiển FSM (Finite State Machine Control Unit).

### Các đặc tính phần cứng chính:
* **Độ rộng Bus dữ liệu (Datapath Width):** 9-bit.
* **Tập thanh ghi (Register File):** Gồm 8 thanh ghi đa năng/chuyên dụng ($R_0$ đến $R_7$). Trong đó, thanh ghi $R_7$ đóng vai trò là **Con trỏ chương trình (Program Counter - PC)** có khả năng tự động tăng chỉ số (`incr_pc`).
* **Khối tính toán ALU:** Đơn vị Cộng/Trừ (Adder/Subtractor) kết hợp với các thanh ghi trung gian ($A$ và $G$).
* **Giải mã Bộ nhớ & Ngoại vi (Memory-Mapped I/O):** Giải mã các bit địa chỉ cao ($A_8A_7$) để phân vùng truy xuất RAM, xuất dữ liệu ra thanh ghi LED/LED 7-đoạn, hoặc đọc dữ liệu từ Switch/Button.
* **Khối điều khiển FSM:** Chu trình FSM đa trạng thái xử lý các bước Giải mã & Thực thi lệnh qua nhiều chu kỳ xung nhịp ($T_0 - T_3$).

---

## 📜 Tập Lệnh Vi Xử Lý (Instruction Set Architecture - ISA)

Lệnh được mã hóa theo **định dạng 9-bit** (`III XXX YYY`):
* `III`: Mã thao tác (Opcode - 3 bit)
* `XXX`: Thanh ghi đích ($R_x$ - 3 bit)
* `YYY`: Thanh ghi nguồn ($R_y$ - 3 bit)

| Lệnh (Assembly) | Định dạng mã máy | Mô tả thao tác |
| :--- | :--- | :--- |
| `mv Rx, Ry` | `000 XXX YYY` | Sao chép dữ liệu: $R_x \leftarrow [R_y]$ |
| `mvi Rx, #D` | `001 XXX 000` | Nạp hằng số tức thời: $R_x \leftarrow \text{Data}$ (Dữ liệu nằm ở byte tiếp theo) |
| `add Rx, Ry` | `010 XXX YYY` | Phép cộng: $R_x \leftarrow [R_x] + [R_y]$ |
| `sub Rx, Ry` | `011 XXX YYY` | Phép trừ: $R_x \leftarrow [R_x] - [R_y]$ |
| `ld Rx, [Ry]` | `100 XXX YYY` | Nạp dữ liệu từ địa chỉ bộ nhớ ngoài $R_y$ vào $R_x$ |
| `st Rx, [Ry]` | `101 XXX YYY` | Ghi dữ liệu từ thanh ghi $R_x$ ra địa chỉ bộ nhớ ngoài $R_y$ |
| `brne Label` | `110 000 ADR` | Nhảy nếu không bằng ($G \neq 0$): $PC \leftarrow \text{Địa chỉ Label}$ |
| `brlt Label` | `111 000 ADR` | Nhảy nếu nhỏ hơn ($G < 0$): $PC \leftarrow \text{Địa chỉ Label}$ |

---

## 🚀 Luồng Thực Thi Lệnh & Khối Điều Khiển FSM

1. **Bước Nhận lệnh - Fetch ($T_0$):** Giá trị con trỏ chương trình PC ($R_7$) được đưa vào thanh ghi địa chỉ `ADDR`. Lệnh tương ứng được đọc từ bộ nhớ vào thanh ghi `IR`, đồng thời PC tự động tăng 1 đơn vị (`incr_pc`).
2. **Bước Giải mã - Decode ($T_1$):** Trích xuất các trường thông tin trong lệnh thông qua mạch giải mã.
3. **Bước Thực thi - Execute ($T_2 - T_3$):** Thực thi nhiều chu kỳ. Đối với các phép toán ALU (`add`/`sub`), toán cục 1 được đưa vào thanh ghi $A$, toán cục 2 đi qua bộ Add/Sub lưu vào thanh ghi $G$, cuối cùng kết quả từ $G$ mới được ghi trả về thanh ghi đích $R_x$.

---

## 🧪 Kiểm Thử & Mô Phỏng (Verification & Simulation)

Toàn bộ testbench nằm trong thư mục [`sim/`](sim), tự kiểm tra kết quả
(self-checking: in `[PASS]`/`[FAIL]` cho từng assertion và tổng kết cuối
cùng, không cần mở waveform để biết đúng/sai):

| File | Phạm vi | Nội dung kiểm thử |
|------|---------|--------------------|
| [`sim/tb.sv`](sim/tb.sv) | Toàn bộ `simple_processor` (tích hợp) | Cả 8 lệnh (MV/MVI/ADD/SUB/LOAD/STORE/BRNE/BRLT), round-trip đọc/ghi RAM, `BRNE`/`BRLT` ở cả hai nhánh taken/not-taken, một chương trình vòng lặp đếm ngược, và khả năng phục hồi sau khi reset giữa chừng một lệnh |
| [`sim/fsm_tb.sv`](sim/fsm_tb.sv) | Riêng `ControlUnitFSM` | Trình tự trạng thái & tín hiệu điều khiển cho từng opcode, hành vi khi `run`/reset đổi giữa chừng, và cách trạng thái `BB1` giải mã cờ rẽ nhánh cho `BRNE`/`BRLT` |
| [`sim/adder_tb.sv`](sim/adder_tb.sv) | Riêng `Fulladder_9bit` | Cộng/trừ theo hướng định sẵn (directed) + ngẫu nhiên, so với mô hình tham chiếu (golden model) |

### Dạng sóng mô phỏng (Simulation Waveform)
*(Hãy thêm ảnh chụp dạng sóng mô phỏng các bus tín hiệu và trạng thái FSM tại đây)*
`![Simulation Waveform](docs/images/waveform_example.png)`

### Sơ đồ mạch RTL (RTL Viewer)
[![RTL Schematic](https://github.com/Daniel-tran1465/custom-9bit-processor-design/blob/main/docs/RTL_Schematic.png)](https://github.com/Daniel-tran1465/custom-9bit-processor-design/blob/main/docs/RTL_Schematic.png)

### ⚠️ Lỗi RTL phát hiện được khi viết testbench

Quá trình viết `sim/adder_tb.sv` và các case `BRNE`/`BRLT` trong
`sim/fsm_tb.sv`/`sim/tb.sv` đã phát hiện ra hai lỗi RTL vốn có từ trước,
chưa từng được testbench cũ (chỉ test `mvi`+`store`) chạy tới:

1. **`rtl/Processor/Fulladder_1bit.sv`: bit tổng (`s`) không phụ thuộc vào
   carry-in.** `assign s = a ^ b_inst ^ ci;` với `b_inst = b ^ ci` — xét
   theo đại số Boolean thì hai số hạng `ci` tự triệt tiêu nhau
   (`a^b^ci^ci = a^b`), nên bất kỳ phép `add`/`sub` nào cần carry/borrow
   lan sang bit kế tiếp đều cho kết quả sai (ví dụ `1+1`, `255+1`, ...).
   Điều này ảnh hưởng tới gần như mọi `ADD`/`SUB` không tầm thường.
   Các case trong `sim/adder_tb.sv` và các test `ADD`/`SUB`/vòng lặp
   trong `sim/tb.sv` **sẽ FAIL** khi chạy trên RTL hiện tại — đúng như
   thiết kế, để chỉ thẳng ra lỗi này.
2. **`rtl/Processor/ControlUnitFSM.sv`: trạng thái `BB1` không phân biệt
   được `BRNE` với `BRLT`.** Cả hai opcode đều dẫn vào chung trạng thái
   `BB1`, và điều kiện rẽ nhánh ở đó chỉ kiểm tra `bbcase != 2'b00`
   (tương đương "G khác 0"). Vì kết quả âm cũng luôn khác 0, điều này vô
   tình đúng với `BRNE`, nhưng có nghĩa `BRLT` sẽ nhảy nhánh với **bất kỳ**
   kết quả khác 0 nào, không chỉ khi kết quả âm. Case
   `"BRLT not taken when G>0"` trong `sim/fsm_tb.sv` sẽ FAIL vì lý do này.

Cả hai lỗi đều **chưa được sửa** trong repo này — testbench được viết để
mô tả đúng hành vi kiến trúc *mong muốn*, nên sẽ báo FAIL rõ ràng thay vì
bị chỉnh cho khớp với đầu ra (sai) hiện tại.

---

## 🛠️ Hướng Dẫn Chạy Mô Phỏng

1. Clone repository này về máy local:
   ```bash
   git clone https://github.com/Daniel-tran1465/custom-9bit-processor-design.git
   ```

2. **Chạy bằng Vivado (GUI):** tạo project mới (hoặc thêm nguồn vào project
   có sẵn), add toàn bộ `rtl/**/*.sv` làm design source, `sim/tb.sv` làm
   simulation source (đặt làm simulation top), `constrs/simple_processor.xdc`
   làm constraints nếu cần synthesis/implementation, rồi **Run Simulation**.
   Muốn chạy `sim/fsm_tb.sv` hoặc `sim/adder_tb.sv` thay vì `sim/tb.sv`, đổi
   simulation top trong *Simulation Settings*, hoặc tạo thêm một simulation
   fileset riêng chỉ chứa file đó.

3. **Chạy bằng dòng lệnh (`xsim`, trong Vivado shell):**
   ```bash
   xvlog -sv rtl/*.sv rtl/Processor/*.sv rtl/Memory/*.sv sim/tb.sv
   xelab tb -s tb_sim
   xsim tb_sim -runall
   ```
   Đổi `sim/tb.sv`/`tb` thành `sim/fsm_tb.sv`/`fsm_tb` hoặc
   `sim/adder_tb.sv`/`adder_tb` để chạy bộ test đơn vị tương ứng. `sim/tb.sv`
   cần `rtl/Memory/my_ROM.mem` nằm trong working directory/search path của
   simulator để `$readmemb` trong `MyROM.sv` phân giải được (Vivado GUI tự
   copy file này khi chạy).
