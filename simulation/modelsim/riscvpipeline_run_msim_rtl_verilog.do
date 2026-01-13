transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+/mnt/shared/sangeeth/Documents/RPI/Semester7/ECSE-4770/Labs/Lab9 {/mnt/shared/sangeeth/Documents/RPI/Semester7/ECSE-4770/Labs/Lab9/riscvpipeline.sv}

