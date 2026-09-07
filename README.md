# Thiết Kế Vi Xử Lý 9-Bit Tuỳ Biến (Custom 9-bit Processor in SystemVerilog)

## 📌 Tổng Quan Dự Án
Repository này chứa toàn bộ mã nguồn thiết kế RTL và kiểm thử chức năng (functional verification) cho **mô hình vi xử lý 9-bit kiến trúc tuỳ biến** bằng ngôn ngữ **SystemVerilog**. 

Dự án được phát triển theo từng giai đoạn nâng cấp: từ một Datapath cơ bản sử dụng Bus dùng chung (Single-Bus Accumulator Architecture) đến một vi xử lý hoàn chỉnh có khả năng chạy vòng lặp, tương tác với bộ nhớ ngoài (RAM/ROM) và các ngoại vi I/O (Đèn LED, LED 7-đoạn, Nút nhấn) thông qua kỹ thuật **Memory-Mapped I/O**, cùng các lệnh rẽ nhánh có điều kiện (Branching instructions).

Dự án được thiết kế, tổng hợp và mô phỏng trên công cụ **Intel Quartus Prime** và **ModelSim / QuestaSim**.

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

Thiết kế đã được mô phỏng và kiểm thử kỹ lưỡng bằng Testbench trên SystemVerilog:
* **Kiểm thử Assembly:** Nạp chương trình chạy mẫu qua file khởi tạo bộ nhớ Memory Initialization File (`.mif`).
* **Kiểm thử Rẽ nhánh & Vòng lặp:** Thực thi thuật toán nhân bằng phép cộng dồn thông qua vòng lặp lệnh `brne`.
* **Truy xuất Ngoại vi:** Kiểm tra logic đọc/ghi dữ liệu từ các ngoại vi như Đèn LED và Nút bấm thông qua bộ giải mã địa chỉ (Address Decoder).

### Dạng sóng mô phỏng (Simulation Waveform)
*(Hãy thêm ảnh chụp dạng sóng mô phỏng các bus tín hiệu và trạng thái FSM tại đây)*
`![Simulation Waveform](docs/images/waveform_example.png)`

### Sơ đồ mạch RTL (RTL Viewer)
*docs/Screenshot 2026-09-07 170935.png*

---

## 🛠️ Hướng Dẫn Chạy Mô Phỏng

1. Clone repository này về máy local:
   ```bash
   git clone [https://github.com/ten-user-cua-ban/custom-9bit-processor-design.git](https://github.com/ten-user-cua-ban/custom-9bit-processor-design.git)
