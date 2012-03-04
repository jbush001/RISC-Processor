module fpga_top(
	input 						clk,
	output reg					output_enable = 0,
	output [31:0]				output_value = 0,
	output						halt_o,
	input							interrupt_request_i);
	

	wire [31:0]				adr;
	wire [31:0]				dat_to_mem;
	wire [31:0]				dat_from_mem;
	wire						stb;
	wire						cyc;
	wire						ack;
	wire [2:0]				cti;
	wire [1:0]				bte;
	wire						we;
	wire [3:0]				sel;
	wire						ram_ack;
	
	cpu c(
		.clock_i(clk),
		.adr_o(adr),
		.dat_i(dat_from_mem),
		.dat_o(dat_to_mem),
		.stb_o(stb),
		.cyc_o(cyc),
		.ack_i(ack),
		.cti_o(cti),
		.bte_o(bte),
		.we_o(we),
		.sel_o(sel),
		.halt_o(halt_o),
		.interrupt_request_i(interrupt_request_i));

	reg ram_enable = 0;
	reg output_ack = 0;
	
	always @*
	begin
		if (we && cyc && stb && adr == 32'ha0000000)
		begin
			ram_enable = 0;
			output_enable = 1;
		end
		else
		begin
			ram_enable = 1;
			output_enable = 0;
		end
	end
	
	assign output_value = data_to_mem;
	assign ack = ram_enable ? ram_ack : output_ack;
	
	always @(posedge clk)
		output_ack <= output_enable;
	
	wb_ram ram(
		.adr_i(adr),
		.dat_i(data_to_mem),
		.dat_o(data_from_mem),
		.stb_i(stb & ram_enable),
		.cyc_i(cyc & ram_enable),
		.ack_o(ram_ack),
		.cti_i(cti),
		.bte_i(bte),
		.we_i(we),
		.sel_i(sel));

endmodule
