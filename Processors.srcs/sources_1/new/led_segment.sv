module led_segment(
input logic clk,
input logic reset,
input logic [8:0] bus,
output logic [2:0] current_digit,
output logic [7:0] anode_out
);

logic [1:0] active_digit;


always_ff@(posedge clk or negedge reset) begin

if(!reset) begin
    active_digit <= 2'b11;
end else begin
    active_digit <= active_digit + 1'b1;
end

end

always_comb begin

case(active_digit)
    2'b00: begin
        current_digit = bus [2:0];
        anode_out = 8'b11111110;
    end
    
    2'b01: begin
        current_digit = bus [5:3];
        anode_out = 8'b11111101;
    end
    
    2'b10: begin
        current_digit = bus [8:6];
        anode_out = 8'b11111011;
    end
    
    default: begin
        current_digit = 3'b000;
        anode_out = 8'b11111111;
    end
endcase
end

endmodule