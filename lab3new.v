//Eliot Bush - Matt Barnes - John Shaffery

module lab3new
(
	//the inputs are the clock and the serial data
	input clk, data_in, reset,
	//the "dummy clock" is the clock which synchronizes with the incoming bitstream
	//i is the input data as read by the sampler and used as the FSM input
	//not really necessary for these to be outputs, but useful for testing 
	output reg dummy_clk, i,
	//output data
	output reg[7:0] data_out,
	output reg[1:0] state, control
);

	//temp storage for output
	reg[7:0] output_store = 0;
	//the counter is used to keep track of how many bits have been read of the current byte
	reg[4:0] counter;
	//this counter is used for generating the secondary clock from the main clock
	reg[8:0] counter_clk=0;
	//this register holds the input data samples
	reg[2:0] samples;
	//this holds the status byte
	reg[7:0] onoff_store;
	//used for determining whether it's a note on or note off
	reg onoff;

	//two main reading states, idle and read
	parameter IDLE = 0, READ = 1;
	//three posssible control states
	parameter STATUS = 0, PITCH = 1, VELOCITY = 2;
	
	//state register
	//reg[1:0] state;
	//control register
	//reg[1:0] control = STATUS;
	initial begin
	state = 0;
	state[0] = 0;
	control = 2'b00;
	end
	
	//this block samples the incoming bitstream and converts it to something usable by the FSM.
	//it also generates a "dummy clock" which has a period 128 times greater than the main clock.
	//the dummy clock is synchronized with the input to the FSM.
	//we chose to sample the input three times per bit and then use voting to determine the bit's value.
	//so 100, 000, and 001 are interpreted as 0, and 011, 111, and 110 are interpreted as 1.
	//we preferred this method because it avoids the issue of trying to synchronize the sampler with the input bitstream.
	//triggers on every clock cycle (the 4 MHz main clock)
	always @ (posedge clk) begin
		//if the counter is at 0, we're starting a new 128-cycle loop
		if (counter_clk==0) begin
			//zero the dummy clock
			dummy_clk <= 0;
			//increment counter
			counter_clk <= counter_clk + 1;
		end
		//if the counter's at 42, we're (roughly) a third of the way through the loop, so we take a sample
		if (counter_clk==42) begin
			samples[0] <= data_in;
			counter_clk <= counter_clk + 1;
		end
		//halfway through the loop, set the dummy clock to 1
		if (counter_clk==64) begin
			dummy_clk <= 1;
			counter_clk <= counter_clk + 1;
		end
		//two thirds of the way through, take another sample
		if (counter_clk==85) begin
			samples[1] <= data_in;
			counter_clk <= counter_clk + 1;
		end
		//completed the loop
		if (counter_clk==127) begin
			//take the last sample
			samples[2] <= data_in;
			//reset the counter
			counter_clk <= 0;
			//if it's 000, 001, or 100, the output is zero
			//if it's 111, 110, or 011, output is one
			i = ((samples[2]+samples[1]+samples[0])>=2);
		end
		else begin
			//increment counter
			counter_clk <= counter_clk + 1;
		end
	end

			

	
	//this block is the sequential logic for the FSM.
	//triggers on the dummy clock, which is synchronized to the FSM input.
	//there are six states. each byte (status, pitch, velocity) has an idle and read state.
	//the idle state actually includes the start and stop bits as well.
	//in terms of implementation we chose to put a case statement for status/pitch/velocity inside the read case statement since idle is identical for all three sub-states.
	always @ (posedge dummy_clk) begin
		if (!reset) begin
			onoff_store = 8'b10000000;
			state <= IDLE;
			control <= STATUS;
		end
		case (state)
			//there's no case statement inside IDLE because it's the same for all three.
			IDLE:
				case (control)
					STATUS:
						//if the input is 0, it's a start bit, move to READ
						if (!i) begin
							counter <= 0;
							state <= READ;
						end
						//otherwise stay in idle
						else begin
							state <= IDLE;
						end
					PITCH:
						//if the input is 0, it's a start bit, move to READ
						if (!i) begin
							counter <= 0;
							state <= READ;
						end
						//otherwise stay in idle
						else begin
							state <= IDLE;
						end
					VELOCITY:
						//if the input is 0, it's a start bit, move to READ
						if (!i) begin
							counter <= 0;
							state <= READ;
						end
						//otherwise stay in idle
						else begin
							state <= IDLE;
						end
				endcase
				
			READ:
				case (control)
					STATUS:
						//if the counter's greater than 7, go to idle pitch
						if(counter>7) begin
							state <= IDLE;
							control <= PITCH;
						end
						//otherwise increment counter and stay in read
						else begin
							//only use the 4 most significant bits (the least significant four are channel number)
							if(counter>3) begin
								onoff_store[counter] <= i;
							end
						counter <= counter + 1;
						state <= READ;
						end	
				
					PITCH:
						//if the counter is greater than 7, go to idle velocity
						if (counter>7)
						begin
							state <= IDLE;
							control <= VELOCITY;
						end
						//if the counter is less than or equal to seven, store the output and stay in READ.
						//the MSB is also stored, but it's always zero for data bytes so it doesn't matter.
						else
						begin
							output_store[counter] <= i;
							counter <= counter + 1;
							state <= READ;
						end
						
					VELOCITY:
						//if the counter is greater than 7, go to idle status
						if (counter>7)
						begin
							state <= IDLE;
							control <= STATUS;
						end
						else
						//otherwise increment the counter and stay in read
						begin
							counter <= counter + 1;
							state <= READ;
						end
				endcase
		endcase
	end
	
	//if onoff_store changes, we might need to change the note on/off flag
	always @ (onoff_store)
		begin
			//1001 - 1000 = 1 note on
			//1000 - 1000 = 0 note off
			//works as "conditional logic" since we'll only get those two control signals
			onoff = onoff_store[7:4] - 8;
		end
	
	//determine the output combinatorially
	always @ (output_store or onoff)
	begin
		//if it's a note on, display the output
		if (onoff) data_out = output_store;
		//if it's a note off, zero it out
		else data_out = 0;
	end

endmodule
