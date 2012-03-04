
`define END_OF_BURST 3'b111

module wb_ram(
	clk_i,
	adr_i,
	dat_i,
	dat_o,
	we_i,
	stb_i,
	ack_o,
	cyc_i,
	bte_i,
	cti_i,
	sel_i);
	input 			clk_i,
					adr_i,
					dat_i,
					we_i,
					stb_i,
					cyc_i,
					bte_i,
					cti_i,
					sel_i;
	output 			dat_o,
					ack_o;
	
	parameter MEMORY_SIZE = 'h10000;
	
	wire 			clk_i,
					we_i,
					stb_i,
					cyc_i;
	wire[31:0]		adr_i,
					dat_i;
	wire[3:0]		sel_i;
	wire[1:0]		bte_i;
	wire[2:0]		cti_i;
	
	reg[31:0]		data[0:MEMORY_SIZE / 4];

	// Ack signal
	reg 			ack_o;
	always @(posedge clk_i)
	begin
		if (cyc_i && stb_i)	
			ack_o <= 1;
		else
			ack_o <= 0;
	end
	
	// Output logic
	integer i;
	initial
	begin
		// synthesis translate_off
		for (i = 0; i < MEMORY_SIZE / 4; i = i + 1)
			data[i] = 0;	

		// synthesis translate_on
	end
	
	wire[31:0] dat_o = data[adr_i[31:2]];

	// Input logic
	always @(posedge clk_i)
	begin
		if (we_i && cyc_i && stb_i)
			data[adr_i[31:2]] <= dat_i;
	end
endmodule
