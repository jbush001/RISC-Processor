
PIPELINE_SRCS = \
	rtl/alu.v \
	rtl/execute_unit.v \
	rtl/instruction_decode_unit.v \
	rtl/instruction_fetch_unit.v \
	rtl/memory_access_unit.v \
	rtl/pipeline.v \
	rtl/register_file.v \
	rtl/write_back_unit.v \
	rtl/branch_prediction_unit.v \
	rtl/primitives.v

PIPELINE_SIM_SRCS = \
	$(PIPELINE_SRCS) \
	testbench/memory.v \
	testbench/pipeline_test_bench.v 

pipeline_sim: $(PIPELINE_SIM_SRCS)
	iverilog -o pipeline_sim $(PIPELINE_SIM_SRCS)

DCACHE_TEST_SRCS = \
	rtl/dcache.v \
	rtl/primatives.v \
	testbench/wb_ram.v \
	testbench/cache_test.v

cache_test: $(DCACHE_TEST_SRCS) 
	iverilog -o cache_test $(DCACHE_TEST_SRCS)

CPU_SRCS = \
	$(PIPELINE_SRCS) \
	rtl/cpu.v \
	rtl/dcache.v \
	rtl/icache.v \
	rtl/arbiter.v \
	rtl/cache_control.v

CPU_SIM_SRCS = \
	$(CPU_SRCS) \
	testbench/cpu_test_bench.v \
	testbench/wb_ram.v

cpu_sim: $(CPU_SIM_SRCS)
	iverilog -o cpu_sim $(CPU_SIM_SRCS)

clean: 
	rm -f pipeline_sim cache_test cpu_sim
