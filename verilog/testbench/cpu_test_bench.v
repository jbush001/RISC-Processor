//`define TRACE

module cpu_test_bench;

	reg 			clock;
	wire[31:0]		adr,
					cpu_dat_out,
					cpu_dat_in;
	wire 			we,
					stb,
					cyc,
					ack;
	wire[1:0]		bte;
	wire[2:0]		cti;
	wire 			halt;
	wire[3:0]		sel;

	wb_ram memory(.clk_i(clock),
		.adr_i(adr),
		.dat_i(cpu_dat_out), 
		.dat_o(cpu_dat_in),
		.we_i(we),
		.stb_i(stb),
		.ack_o(ack),
		.cyc_i(cyc),
		.bte_i(bte),
		.cti_i(cti),
		.sel_i(sel)); 
	cpu cpu(.clock_i(clock),
		.adr_o(adr),
		.dat_o(cpu_dat_out),
		.dat_i(cpu_dat_in),
		.we_o(we),
		.stb_o(stb),
		.cyc_o(cyc),
		.ack_i(ack),
		.bte_o(bte),
		.cti_o(cti),
		.halt_o(halt),
		.sel_o(sel),
		.interrupt_request_i(terminal_count));

	// Timer
	reg[5:0]		timer_count;
	wire 			terminal_count;

	assign terminal_count = timer_count == 0;
	
	initial
		timer_count <= 0;

	always @(posedge clock)
	begin
		if (terminal_count)
			timer_count <= 50;
		else
			timer_count <= timer_count - 1;
	end

	reg[1000:0]	code_filename;
	initial
	begin
		#5 clock = 0;

		if ($value$plusargs("bin=%s", code_filename))
			$readmemh(code_filename, memory.data);
		else
		begin
			$display("error opening file");
			$finish;
		end

`ifdef TRACE
		$dumpfile("trace.vcd");
		$dumpvars(100, cpu);
`endif

		while (~halt)
		begin
			#5 clock = 0;
			#5 clock = 1;
		end
	end
endmodule
