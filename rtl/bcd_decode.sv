module bcd_decode(
input logic [2:0] bcd,
output logic [7:0] ssd_cathode_out
);

always_comb begin
case(bcd)
    3'b000: ssd_cathode_out = 8'b00000011 ;
    3'b001: ssd_cathode_out = 8'b10011111 ;
    3'b010: ssd_cathode_out = 8'b00100101 ;
    3'b011: ssd_cathode_out = 8'b00001101 ;
    3'b100: ssd_cathode_out = 8'b10011001 ;
    3'b101: ssd_cathode_out = 8'b01001001 ;
    3'b110: ssd_cathode_out = 8'b01000001 ;
    3'b111: ssd_cathode_out = 8'b00011111 ;
    default: ssd_cathode_out = 8'b00000011;
endcase
end

endmodule