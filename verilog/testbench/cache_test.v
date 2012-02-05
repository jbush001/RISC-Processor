module cache_test;

	reg 			clock;
	reg[31:0]		cache_address,
					cache_data_in;
	reg 			cache_write,
					cache_read;
	reg 			cache_reset;
	reg 			ack;
	reg[31:0]		dat_i;
	reg[3:0]		cache_select;

	wire[31:0]		cache_data_out,
					dat_o;
	wire 			cache_ready;
	wire[31:0]		adr;
	wire[2:0]		cti;
	wire 			stb,
					cyc,
					we;

	cache cache(.clock_i(clock),
		.reset_i(cache_reset),
		.address_i(cache_address),
		.read_enable_i(cache_read),
		.write_enable_i(cache_write),
		.cache_select_i(cache_select),
		.ready_o(cache_ready),
		.cached_data_o(cache_data_out),
		.cached_data_i(cache_data_in),
		.adr_o(adr),
		.dat_i(dat_i),
		.dat_o(dat_o),
		.stb_o(stb),
		.cyc_o(cyc),
		.ack_i(ack),
		.cti_o(cti),
		.we_o(we));

	task fail;
		input[200:0] message;
	begin
		$display("fail %s", message);
		$finish;
	end	
	endtask

	task validate_burst;
		input[31:0] expected_address;
		input[1:0]	wait_state_count;
		input 		expected_we;
		input 		last_clock;
		input[31:0] change_address;
		
		integer i, j;
	begin
		#5 clock <= 1;
		#5 clock <= 0;

		if (~cyc || ~stb || we != expected_we || cache_ready)
			fail("1");

		if (adr != expected_address)
			fail("2");

		#1 if (cti != 3'b010)
			fail("3");

		// 1. Address phase.
		ack <= 0;
		for (i = 0; i < wait_state_count; i = i + 1)
		begin
			#5 clock <= 1;
			#5 clock <= 0;
			if (~cyc || ~stb || we != expected_we || cache_ready)
				fail("4");
		end
		
		ack <= 1;
		#5 clock <= 1;
		#5 clock <= 0;
		
		if (change_address != 0)
			cache_address <= change_address;
		
		// 2. Data phase (first 7 accesses)
		for (i = 0; i < 7; i = i + 1)
		begin
			ack <= 0;
			for (j = 0; j < wait_state_count; j = j + 1)
			begin
				#5 clock <= 1;
				#5 clock <= 0;
				if (~cyc || ~stb || we != expected_we)
					fail("5");
			end

			if (expected_we)
			begin
				if (dat_o != expected_address)
					fail("5.5");
			end
			else
				dat_i <= expected_address;
				
			// else validate data that is being written
				
			ack <= 1;
			#1 if (cti != 3'b010)
				fail("6");

			#4 clock <= 1;
			#4 clock <= 0;

			expected_address <= expected_address + 4;
			#1 if (adr != expected_address)
				fail("7");
		end
	
		// 3. End of burst
		#1 if (cti != 3'b111)
			fail("8");

		if (last_clock)
		begin
			#5 clock <= 1;
			#5 clock <= 0;
		end
	end
	endtask

	task validate_cache_ready;
	begin
		#1 if (~cache_ready)
			fail("cache_not_ready");

		if (cyc || stb)
			fail("bus cycle not terminated");
	end
	endtask

	initial
	begin
		clock <= 0;
		cache_reset <= 1;
		cache_write <= 0;
		cache_read <= 1;
		cache_address <= 0;
		cache_select <= 4'b1111;
		ack <= 0;
		#5 cache_reset <= 0;

		// Test 1: read a line.  This should be fetched from memory
		$display("test 1");
		cache_address <= 32;
		#5 validate_burst(32, 0, 0, 1, 0);
		#1 if (cache_data_out != 32)
			fail("test 1");
	
		validate_cache_ready;
		
		// xxx check returned value
		
		// Test 2: read another word from the same line.  No memory fetch should occur.
		// Ensure the data is correct.
		$display("test 2");
		cache_address <= 36;
		validate_cache_ready;

		if (cache_data_out != 36)
			fail("test 1");

		// xxx check returned value

		// Test 3: Read a line that collides with this line.  The line should not be written
		// back and a new line should be fetched
		$display("test 3");
		cache_address <= 'h8000 + 32;
		#5 validate_burst('h8000 + 32, 0, 0, 1, 0);
		if (cache_data_out != 'h8000 + 32)
			fail("test 3");

		validate_cache_ready;

		// 3.5: Make another access to the same line to ensure tag ram was updated
		$display("test 3.5");
		cache_address <= 'h8000 + 36;
		validate_cache_ready;

		if (cache_data_out != 'h8000 + 36)
			fail("test 3.5");

		// Test 4: Read a new line, but try with wait states.
		$display("test 4");
		cache_address <= 32;
		#5 validate_burst(32, 1, 0, 1, 0);
		if (cache_data_out != 32)
			fail("test 4");

		// Test 5: Read a line, write to it, then read from it again.  Then read a line that
		// collides with this line.  The line should be written back before a new line is fetched.
		$display("test 5");
		cache_address <= 64;
		#5 validate_burst(64, 0, 0, 1, 0);
		if (cache_data_out != 64)
			fail("test 5");

		// Write request to same line
		cache_read <= 0;
		cache_write <= 1;
		#5 clock <= 1;
		#5 clock <= 0;
		validate_cache_ready;

		// Another read request for the same line (ensure the read doesn't clear out the dirty bit)
		cache_write <= 0;
		cache_read <= 1;
		#5 clock <= 1;
		#5 clock <= 0;
		validate_cache_ready;

		// Now touch a colliding line and ensure the dirty line is flushed back 
		cache_address <= 'h8000 + 64;
		#5 validate_burst(64, 0, 1, 0, 0);	// Write back
		#5 validate_burst('h8000 + 64, 0, 0, 1, 0);	// Read new line
		if (cache_data_out != 'h8000 + 64)
		begin
			$display("cache_data_out = %x", cache_data_out);
			fail("test 5.5: 3");
		end

		// Read yet another colliding line and ensure the dirty bit was cleaned on the last flush.
		cache_address <= 'h10000 + 64;
		#5 validate_burst('h10000 + 64, 0, 0, 1, 0);	// Read new line
		if (cache_data_out != 'h10000 + 64)
			fail("test 5.5: 4");

		// Collide again with a write to ensure it is updated correctly and old line is
		// not re-written.
		$display("writing value");
		cache_write <= 1;
		cache_read <= 0;

		cache_data_in <= 'hcafebabe;
		cache_address <= 'h8000 + 64;
		#5 validate_burst('h8000 + 64, 0, 0, 1, 0);	// Read new line
		#5 clock <= 1;
		#5 clock <= 0;
		validate_cache_ready;

		if (cache_data_out != 'hcafebabe)
			fail("test 5.5: 5");
		
		validate_cache_ready;

		// Read an adjacent line
		
		$display("read adjacent line");
		cache_write <= 0;
		cache_read <= 1;
		cache_address <= 'h8000 + 68;
		#5 clock <= 1;
		#5 clock <= 0;
		validate_cache_ready;

		#1 if (cache_data_out != 'h8000 + 68)
		begin
			$display("test 5.7: %x", cache_data_out);
			fail("test 5.7");
		end
		
		// Test 6: Test addressing each byte lane.
		$display("begin test 6");
		cache_address <= 'h8000 + 64;
		cache_write <= 1;
		cache_read <= 0;
		cache_select <= 4'b1111;
		cache_data_in <= 'haabbccdd;

		#5 clock <= 1;
		#5 clock <= 0;
		validate_cache_ready;

		cache_write <= 0;
		cache_read <= 1;
		#1 validate_cache_ready;
		#1 if (cache_data_out != 'haabbccdd)
			fail("test 6: 1");
		
		cache_select <= 4'b0001;
		cache_data_in = 'h00000099;
		cache_write <= 1;
		cache_read <= 0;

		#5 clock <= 1;
		#5 clock <= 0;
		validate_cache_ready;

		cache_write <= 0;
		cache_read <= 1;
		#1 validate_cache_ready;
		if (cache_data_out != 'haabbcc99)
			fail("test 6: 2");

		cache_select <= 4'b0010;
		cache_data_in = 'h00008800;
		cache_write <= 1;
		cache_read <= 0;

		#5 clock <= 1;
		#5 clock <= 0;
		validate_cache_ready;

		cache_write <= 0;
		cache_read <= 1;
		#1 validate_cache_ready;
		if (cache_data_out != 'haabb8899)
			fail("test 6: 3");

		cache_select <= 4'b0100;
		cache_data_in = 'h00770000;
		cache_write <= 1;
		cache_read <= 0;

		#5 clock <= 1;
		#5 clock <= 0;
		validate_cache_ready;

		cache_write <= 0;
		cache_read <= 1;
		#1 validate_cache_ready;
		if (cache_data_out != 'haa778899)
			fail("test 6: 4");

		cache_select <= 4'b1000;
		cache_data_in = 'h66000000;
		cache_write <= 1;
		cache_read <= 0;

		#5 clock <= 1;
		#5 clock <= 0;
		validate_cache_ready;

		cache_write <= 0;
		cache_read <= 1;
		#1 validate_cache_ready;
		if (cache_data_out != 'h66778899)
			fail("test 6: 5");
		
		// Test 7: test changing read address in the middle of a cache line fetch
		$display("begin test 7");

		cache_address <= 128;
		#5 validate_burst(128, 0, 0, 1, 192);	// Will finish first burst
		#5 validate_burst(192, 0, 0, 1, 0);		// Start second burst
		#1 if (cache_data_out != 192)
			fail("test 7");
	
		validate_cache_ready;


		$display("all tests passed");
	end	
endmodule

