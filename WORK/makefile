MODEL  = ../MODEL/alu.v
BENCH  = ../BENCH/alu_tb.v
SYNTHF = ../SYNTH/alu_synth.v

.PHONY: all sim_model synth sim_synth waves clean

all: sim_model synth sim_synth

sim_model:
	iverilog -g2005 -o sim_model.vvp $(BENCH) $(MODEL)
	vvp sim_model.vvp

synth:
	mkdir -p ../SYNTH
	yosys -l ../SYNTH/yosys.log -p "read_verilog $(MODEL); synth -top alu -flatten; opt_clean; stat; write_verilog -noattr $(SYNTHF)"

sim_synth: $(SYNTHF)
	iverilog -g2005 -o sim_synth.vvp $(BENCH) $(SYNTHF)
	vvp sim_synth.vvp

$(SYNTHF):
	$(MAKE) synth

waves:
	gtkwave tb_alu.vcd &

clean:
	rm -f *.vvp *.vcd

