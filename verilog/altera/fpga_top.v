module fpga_top(
	input 						clk,
	output [31:0]				adr_o,
	input [31:0]				dat_i,
	output [31:0]				dat_o,
	output						stb_o,
	output						cyc_o,
	input							ack_i,
	output [2:0]				cti_o,
	output [1:0]				bte_o,
	output						we_o,
	output [3:0]				sel_o,
	output						halt_o,
	input							interrupt_request_i);
	
	
	
	cpu c(
		.clock_i(clk),
		.adr_o(adr_o),
		.dat_i(dat_i),
		.dat_o(dat_o),
		.stb_o(stb_o),
		.cyc_o(cyc_o),
		.ack_i(ack_i),
		.cti_o(cti_o),
		.bte_o(bte_o),
		.we_o(we_o),
		.sel_o(sel_o),
		.halt_o(halt_o),
		.interrupt_request_i(interrupt_request_i));


endmodule
