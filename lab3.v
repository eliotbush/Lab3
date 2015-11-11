module lab3(i, 
			o,
			clk,
			ctrl,);

	input i;
	input clk;
	input ctrl;
	output o;
	wire i;
	reg[6:0] o;

parameter [1:0] IDLE = 2'b00,
				READ = 2'b01,
				END = 2'b10;
			
reg [1:0] state, next;
reg [3:0] counter = 0;

always @(posedge clk)
	if (!ctrl) state <= IDLE;
	else	   state <= next;
	
always @(state or i) begin
	next = 2'bx;
	case (state)
		IDLE: if (!i) next = READ;
			  else    next = IDLE;
		
		READ: if (counter<7) begin 
				next = READ;
				counter = counter + 1;
			  end else begin		
			    next = END;
			    end
			   
	    END: begin next = IDLE;
			       counter = 0;
	    end
	endcase
end
endmodule 
