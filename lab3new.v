//this block works as the FSM for the pitch byte.
//note on/off is treated as an input signal right now, will be internal once status byte is implemented

module lab3new
(
	input clk, data_in, onoff,
	output reg[7:0] data_out
);

	//state register
	reg[1:0] state;
	//temp storage for output
	reg[7:0] output_store = 0;
	//counter for READ state
	reg[4:0] counter;

	parameter IDLE = 0, READ = 1, END = 2;
	
	//determine next state (synchronous, use non-blocking assignments)
	always @ (posedge clk) begin
		case (state)
			IDLE:
				//if the input is 0, it's a start bit, move to READ
				if (!data_in)
				begin
					counter <= 0;
					state <= READ;
				end
				//otherwise stay in idle
				else
				begin
					state <= IDLE;
				end
				
			READ:
				//if the counter is greater than 7, move on to END
				if (counter>7)
				begin
					state <= END;
				end
				//if the counter is less than or equal to seven, store the output and stay in READ.
				//the MSB is also stored, but it's always zero for data bytes so it doesn't matter.
				else
				begin
					output_store[counter] <= data_in;
				    counter <= counter + 1;
					state <= READ;
				end
			//END just covers the stop bit so it eats one cycle and moves to IDLE
			END:
					state <= IDLE;
		endcase
	end
	
	//determine the output. asynchronous: use blocking assignments
	always @ (onoff)
	begin
		if (onoff) data_out = output_store;
		else data_out = 0;
	end

endmodule
