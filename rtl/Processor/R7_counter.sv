module R7_Counter (
input logic clk,
input logic reset,
input logic enable,
input logic counter_en,
input logic [8:0] Rin,
output logic [8:0] Rout
);

always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            Rout <= 9'b0;
        end else begin
            if (enable) begin
                Rout <= Rin;       
            end else if (counter_en) begin
                Rout <= Rout + 1'b1;  
            end

        end
    end


endmodule

