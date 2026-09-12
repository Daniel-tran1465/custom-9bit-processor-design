module ControlUnitFSM (
input logic run,
input logic resetn,
input logic clk,
input logic [8:0] IRout,
input logic G_nonzero,
input logic G_lessthanzero,
output logic IRin,
output logic [7:0] R_out,
output logic Gout,
output logic DINout,
output logic [7:0] R_in,
output logic Ain,
output logic AddSub,
output logic Gin,
output logic Done,
output logic ADDRin,
output logic DOUTin,
output logic W_D,
output logic incr_pc
);

typedef enum logic [4:0] {
    MV     = 5'b00000,
    MVI    = 5'b00001,
    ADD    = 5'b00010,
    SUB    = 5'b00011,
    LOAD   = 5'b00100,
    STORE = 5'b00101,
    BRNE = 5'b00110,
    BRLT = 5'b00111,
    SUB_S2 = 5'b01000,
    SUB_S3 = 5'b01001,
	 DECODE = 5'b01010,
	 LOAD_L2 = 5'b01011,
	 ADD_T2 = 5'b01101,
	 STORE_S2 = 5'b01110,
	 MVI_T2 = 5'b10000,
	 FETCH = 5'b10001,
	 ADD_T3 = 5'b10010,
	 BB1 = 5'b10011,
	 BB2 = 5'b10100,
	 IDLE = 5'b10101,
	 SELECTING = 5'b10110,
	 FETCH_WAIT = 5'B10111
} state_e;

logic [3:0] opcode;
logic [2:0] Rx;
logic [2:0] Ry;
logic brne, brlt;
logic [1:0] bbcase;

state_e current_state, next_state;

logic rst;


always_ff @(posedge clk or negedge resetn) begin
        if (!resetn)
            current_state <= IDLE;
        else begin
            if(run == 1'b1)
                current_state <= next_state;
            else
                current_state <= IDLE;
            end
            
    end

assign opcode = {2'b0, IRout[8:6]};
assign Rx = IRout[5:3];
assign Ry = IRout[2:0];

assign brne = G_nonzero;
assign brlt = G_lessthanzero;

assign bbcase = {brlt, brne};


always_comb begin

next_state = current_state;
Done = 1'b0;
rst = resetn;

R_in       = 8'b0000_0000;
R_out      = 8'b0000_0000;
IRin       = 1'b0;
DINout     = 1'b0;
Ain        = 1'b0;
Gin        = 1'b0;
Gout       = 1'b0;
AddSub     = 1'b0;
ADDRin 	  = 1'b0;
DOUTin 	  = 1'b0;
W_D 		  = 1'b0;
incr_pc    = 1'b0;

case (current_state)
        MV: begin
            R_in  = (8'b1 << Rx);
            R_out = (8'b1 << Ry);
				Done = 1'b1;
            next_state = FETCH;
        end
        
        MVI: begin
            R_out   = 8'b10000000;
            ADDRin = 1'b1;
			incr_pc = 1'b1;
            next_state = MVI_T2;
        end
		  
		  MVI_T2: begin
			DINout = 1'b1;
            R_in   = (8'b1 << Rx);
            Done   = 1'b1;
            next_state = FETCH;
		  end
        
        ADD: begin
            R_out = (8'b1 << Rx);
            Ain   = 1'b1;
            next_state = ADD_T2; 
        end

        ADD_T2: begin
            R_out  = (8'b1 << Ry);
            AddSub = 1'b0; 
            Gin    = 1'b1;
            next_state = ADD_T3;
        end

        ADD_T3: begin
            Gout = 1'b1;
            R_in = (8'b1 << Rx);
				Done = 1'b1;
            next_state = FETCH;
        end
        
        SUB: begin
            R_out = (8'b1 << Rx);
            Ain   = 1'b1;
            next_state = SUB_S2;
        end

        SUB_S2: begin
            R_out  = (8'b1 << Ry);
            AddSub = 1'b1; 
            Gin    = 1'b1;
            next_state = SUB_S3;
        end

        SUB_S3: begin
            Gout = 1'b1;
            R_in = (8'b1 << Rx);
				Done = 1'b1;
            next_state = FETCH;
        end
		  
		  LOAD: begin
				R_out = (8'b1 << Ry);
				ADDRin = 1'b1;
				next_state = LOAD_L2;
		  end
		 	  
		  LOAD_L2: begin
				R_in = (8'b1 << Rx);
				DINout = 1'b1;
				Done = 1'b1;
				next_state = FETCH;
		  end
		  
		  STORE: begin
				R_out = (8'b1 << Ry);
				ADDRin = 1'b1;
				next_state = STORE_S2;
		  end
		  
		  STORE_S2: begin
		  		R_out = (8'b1 << Rx);
				DOUTin = 1'b1;
				W_D = 1'b1;
				Done = 1'b1;
				next_state = FETCH;
		  end
		  
		  BRNE: begin
				R_out = 8'b10000000;
				ADDRin = 1'b1;
				incr_pc = 1'b1;
				next_state = BB1;
		  end
		  
		  BRLT: begin
				R_out = 8'b10000000;
				ADDRin = 1'b1;
				incr_pc = 1'b1;
				next_state = BB1;
		  end
		  	  
		  BB1: begin
				case(bbcase)
					2'b00: begin
							 Done = 1'b1;
							 next_state = FETCH;
							end
							
					default: next_state = BB2;
				endcase
		  end
		  
		  BB2: begin
				DINout = 1'b1;
				R_in = 8'b10000000;
				Done = 1'b1;
				next_state = FETCH;
		  end
		  
		  FETCH: begin
				incr_pc = 1'b1;
				R_out = 8'b10000000;
				ADDRin = 1'b1;
				next_state = FETCH_WAIT;
		  end
		  
		  FETCH_WAIT: begin
		      IRin = 1'b1;
		      next_state = DECODE;
		  end
		  
		  IDLE: begin
		        Done = 1'b0;
		        rst = 1'b1;
		        next_state = SELECTING;
		  end
		  
		  SELECTING: begin
		      case(run)
		          1'b1: next_state = FETCH;
		          default: next_state = IDLE;
		      endcase
		  end
		  
        DECODE: begin
            case (opcode)
                5'b00000: next_state = MV;
                5'b00001: next_state = MVI;
                5'b00010: next_state = ADD;
                5'b00011: next_state = SUB;
			    5'b00100: next_state = LOAD;
			    5'b00101: next_state = STORE;
			    5'b00110: next_state = BRNE;
			    5'b00111: next_state = BRLT;
                default: next_state = IDLE;
            endcase
        end
        
        default: next_state = IDLE;
    endcase
end


endmodule
