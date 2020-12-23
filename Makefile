# Makefile

CC       = iverilog
TMP      = tb/tmp
VCD      = vcd
FAIL     = FAIL
EXPECTED = tb/expected
RUN      = ${TMP}/out_bin

TESTS = \
	ALU \
	Interrupt \
	RegisterFile \
	Shifter \
	Inst_flags \
	Inst_ldx \
	Inst_ldy \
	Inst_ld \
	Inst_t \
	Inst_lda \
	Inst_ops \
	Inst_sta \
	Inst_b \
	Inst_inc \
	Inst_dec \
	Inst_inde \
	Inst_asl \
	Inst_shift \
	Inst_bit \
	Inst_st \
	Inst_cp \
	Inst_stack \
	Inst_jmp \
	Inst_brk \
	Inst_jsr

FULLSRC	= \
	rtl/cpu.v \
	rtl/interrupt.v \
	rtl/register_file.v \
	rtl/status_register.v \
	rtl/decoder.v \
	rtl/mem_controller.v \
	rtl/exec_controller.v \
	rtl/alu.v \
	rtl/shifter.v \
	rtl/ram/ram_64k_8.v \
	rtl/ram/ram.v

RESULTS	= $(addsuffix .result, $(TESTS))
FILTER	= grep -v 'VCD info*' | grep -v 'WARNING*'

all: $(RESULTS)

clean:
	rm -rf ${TMP} ${VCD} ${FAIL} ${RUN}

%.result:
	@mkdir -p ${TMP} ${VCD}
	@$(CC) -Wall -Wno-timescale -Irtl -DTEST=\"$*\" -o ${RUN} $^ && \
	  ${RUN} | $(FILTER) > ${TMP}/$@
	@diff -c ${EXPECTED}/$* ${TMP}/$@ > ${TMP}/$*.diff; \
	if [ $$? -eq 0 ]; then \
		echo "[ \e[00;32mPASS\e[0m ] $*"; \
	else \
		echo "[ \e[01;31mFAIL\e[0m ] $* \t\t-- Check directory FAIL/ for details"; \
		mkdir -p ${FAIL}; \
		mv ${TMP}/$*.diff ${FAIL}; \
	fi \

ALU.result: tb/alu_tb.v rtl/alu.v
Shifter.result: tb/shifter_tb.v rtl/shifter.v
Interrupt.result: tb/interrupt_tb.v rtl/interrupt.v
RegisterFile.result: tb/register_file_tb.v rtl/register_file.v rtl/status_register.v
Inst_flags.result: tb/instruction_tb.v $(FULLSRC)
Inst_ldx.result: tb/instruction_tb.v $(FULLSRC)
Inst_ldy.result: tb/instruction_tb.v $(FULLSRC)
Inst_ld.result: tb/instruction_tb.v $(FULLSRC)
Inst_t.result: tb/instruction_tb.v $(FULLSRC)
Inst_lda.result: tb/instruction_tb.v $(FULLSRC)
Inst_ops.result: tb/instruction_tb.v $(FULLSRC)
Inst_sta.result: tb/instruction_tb.v $(FULLSRC)
Inst_b.result: tb/instruction_tb.v $(FULLSRC)
Inst_inc.result: tb/instruction_tb.v $(FULLSRC)
Inst_dec.result: tb/instruction_tb.v $(FULLSRC)
Inst_inde.result: tb/instruction_tb.v $(FULLSRC)
Inst_asl.result: tb/instruction_tb.v $(FULLSRC)
Inst_shift.result: tb/instruction_tb.v $(FULLSRC)
Inst_bit.result: tb/instruction_tb.v $(FULLSRC)
Inst_st.result: tb/instruction_tb.v $(FULLSRC)
Inst_cp.result: tb/instruction_tb.v $(FULLSRC)
Inst_stack.result: tb/instruction_tb.v $(FULLSRC)
Inst_jmp.result: tb/instruction_tb.v $(FULLSRC)
Inst_brk.result: tb/instruction_tb.v $(FULLSRC)
Inst_jsr.result: tb/instruction_tb.v $(FULLSRC)
