
`include "defines1.v"

module openmips(

    input wire  clk,
	input wire  rst,
	
	input wire[`RegBus] rom_data_i,
	output wire[`RegBus] rom_addr_o,
	output wire          rom_ce_o,

	//连接数据存储器data_ram
	input wire[`RegBus]           ram_data_i,
	output wire[`RegBus]           ram_addr_o,
	output wire[`RegBus]           ram_data_o,
	output wire                    ram_we_o,
	output wire[3:0]               ram_sel_o,
	output wire[3:0]               ram_ce_o
);

    wire[`InstAddrBus] pc;
	wire[`InstAddrBus] id_pc_i;
	wire[`RegBus] id_inst_i;
	
	//ID和ID/EX
	wire[`AluOpBus] id_aluop_o;
	wire[`AluSelBus] id_alusel_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_wreg_o;
	wire[`RegAddrBus] id_wd_o;
	wire id_is_in_delayslot_o;
  wire[`RegBus] id_link_address_o;	
	//ID/EX和EX
	wire[`AluOpBus] ex_aluop_i;
	wire[`AluSelBus] ex_alusel_i;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire ex_wreg_i;
	wire[`RegAddrBus] ex_wd_i;
	wire ex_is_in_delayslot_i;	
  wire[`RegBus] ex_link_address_i;	
	//EX和EX/MEM
	wire ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus] ex_wdata_o;
	wire[`RegBus] ex_hi_o;
	wire[`RegBus] ex_lo_o;
	wire ex_whilo_o;
	//EX/MEM和MEM
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	wire[`RegBus] mem_hi_i;
	wire[`RegBus] mem_lo_i;
	wire mem_whilo_i;
	//MEM和MEM/WB
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	wire[`RegBus] mem_hi_o;
	wire[`RegBus] mem_lo_o;
	wire mem_whilo_o;	
	//MEM/WB的输出与写会
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	wire[`RegBus] wb_hi_i;
	wire[`RegBus] wb_lo_i;
	wire wb_whilo_i;
	//连接译码阶段ID和通用寄存器的连线
	wire reg1_read;
	wire reg2_read;
	wire[`RegBus] reg1_data;
	wire[`RegBus] reg2_data;
	wire[`RegAddrBus] reg1_addr;
	wire[`RegAddrBus] reg2_addr;
	
	//连接执行阶段与hilo模块的输出，读取HI、LO寄存器
	wire[`RegBus] 	hi;
	wire[`RegBus]   lo;
	
	//连接执行阶段与ex_reg模块，用于多周期的MADD、MADDU、MSUB、MSUBU指令
	wire[`DoubleRegBus] hilo_temp_o;
	wire[1:0] cnt_o;
	
	wire[`DoubleRegBus] hilo_temp_i;
	wire[1:0] cnt_i;

	//用于连接除法模块的 
	wire[`DoubleRegBus] div_result;
	wire div_ready;
	wire[`RegBus] div_opdata1;
	wire[`RegBus] div_opdata2;
	wire div_start;
	wire div_annul;
	wire signed_div;
	
	wire is_in_delayslot_i;
	wire is_in_delayslot_o;
	wire next_inst_in_delayslot_o;
	wire id_branch_flag_o;
	wire[`RegBus] branch_target_address;
	
	wire[5:0] stall;
	wire stallreq_from_id;	
	wire stallreq_from_ex;
	
	//pc_reg例化
	pc_reg pc_reg0(
	    .clk(clk),
		.rst(rst),
		.stall(stall),
		.branch_flag_i(id_branch_flag_o),
		.branch_target_address_i(branch_target_address),
		.pc(pc),
		.ce(rom_ce_o)
	
	);
	
	assign rom_addr_o = pc;
	
	//IF/ID模块
	if_id if_id0(
	    .clk(clk),
		.rst(rst),
		.stall(stall),
		.if_pc(pc),
		.if_inst(rom_data_i),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)
	
	);
	
	//译码阶段ID
	id id0(
	    .rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),
		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),
		
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read),
		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr),
		
		.aluop_o(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),
		.wreg_o(id_wreg_o),
		
		.is_in_delayslot_i(is_in_delayslot_i),
		 
		//处于执行阶段要写入目的寄存器的信息
		.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),
		//处于访存阶段要写入目的寄存器的信息
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),
		
		.next_inst_in_delayslot_o(next_inst_in_delayslot_o),	
		.branch_flag_o(id_branch_flag_o),
		.branch_target_address_o(branch_target_address),       
		.link_addr_o(id_link_address_o),
		
		.is_in_delayslot_o(id_is_in_delayslot_o),
		
		.stallreq(stallreq_from_id)
	
	);
	
	//寄存器例化
	regfile regfile1(
	    .clk(clk),
		.rst(rst),
		.we(wb_wreg_i),
		.waddr(wb_wd_i),
		.wdata(wb_wdata_i),
		.re1(reg1_read),
		.raddr1(reg1_addr),
		.rdata1(reg1_data),
		.re2(reg2_read),
		.raddr2(reg2_addr),
		.rdata2(reg2_data)
	
	);
	
	//ID/EX模块
	id_ex id_ex0(
	    .clk(clk),
		.rst(rst),
		
		.stall(stall),
		
		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_werg(id_wreg_o),
		.id_link_address(id_link_address_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),
		
		.ex_aluop(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_wreg(ex_wreg_i),
		.ex_link_address(ex_link_address_i),
  	.ex_is_in_delayslot(ex_is_in_delayslot_i),
		.is_in_delayslot_o(is_in_delayslot_i)	
	
	);
	
	//EX模块
	ex ex0(
	   .rst(rst),
	   
	   .aluop_i(ex_aluop_i),
	   .alusel_i(ex_alusel_i),
	   .reg1_i(ex_reg1_i),
	   .reg2_i(ex_reg2_i),
	   .wd_i(ex_wd_i),
	   .wreg_i(ex_wreg_i),
	   .hi_i(hi),
		.lo_i(lo),

	  .wb_hi_i(wb_hi_i),
	  .wb_lo_i(wb_lo_i),
	  .wb_whilo_i(wb_whilo_i),
	  .mem_hi_i(mem_hi_o),
	  .mem_lo_i(mem_lo_o),
	  .mem_whilo_i(mem_whilo_o),
	  
	  .hilo_temp_i(hilo_temp_i),
	  .cnt_i(cnt_i),
	  .div_result_i(div_result),
		.div_ready_i(div_ready), 
	  
	  .link_address_i(ex_link_address_i),
		.is_in_delayslot_i(ex_is_in_delayslot_i),
	  
	   .wd_o(ex_wd_o),
	   .wreg_o(ex_wreg_o),
	   .wdata_o(ex_wdata_o),
	   .hi_o(ex_hi_o),
		.lo_o(ex_lo_o),
		.whilo_o(ex_whilo_o),
		
		.hilo_temp_o(hilo_temp_o),
		.cnt_o(cnt_o),
		
		.div_opdata1_o(div_opdata1),
		.div_opdata2_o(div_opdata2),
		.div_start_o(div_start),
		.signed_div_o(signed_div),	
		
		.stallreq(stallreq_from_ex)
	
	);
	
	//EX/MEM
	ex_mem ex_mem0(
	    .clk(clk),
		.rst(rst),
		
		.stall(stall),
		
		.ex_wd(ex_wd_o),
		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),
		.ex_hi(ex_hi_o),
		.ex_lo(ex_lo_o),
		.ex_whilo(ex_whilo_o),
		.hilo_i(hilo_temp_o),
		.cnt_i(cnt_o),	
		
		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_wdat(mem_wdata_i),
		.mem_hi(mem_hi_i),
		.mem_lo(mem_lo_i),
		.mem_whilo(mem_whilo_i),
        .hilo_o(hilo_temp_i),
		.cnt_o(cnt_i)	
	
	);
	
	//MEM
	mem mem0(
	    .rst(rst),
		
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
		.hi_i(mem_hi_i),
		.lo_i(mem_lo_i),
		.whilo_i(mem_whilo_i),	
		
		.aluop_i(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),
	
		//来自memory的信息
		.mem_data_i(ram_data_i),
		
		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),
		.hi_o(mem_hi_o),
		.lo_o(mem_lo_o),
		.whilo_o(mem_whilo_o),
		
		//送到memory的信息
		.mem_addr_o(ram_addr_o),
		.mem_we_o(ram_we_o),
		.mem_sel_o(ram_sel_o),
		.mem_data_o(ram_data_o),
		.mem_ce_o(ram_ce_o)		
	   
	);
	
	//MEM/WB
	mem_wb mem_wb0(
	    .clk(clk),
		.rst(rst),
		
		.stall(stall),
		
		.mem_wd(mem_wd_o),
		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),
		.mem_hi(mem_hi_o),
		.mem_lo(mem_lo_o),
		.mem_whilo(mem_whilo_o),
		
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i),
		.wb_hi(wb_hi_i),
		.wb_lo(wb_lo_i),
		.wb_whilo(wb_whilo_i)
	
	);
	
	hilo_reg hilo_reg0(
		.clk(clk),
		.rst(rst),
	
		//写端口
		.we(wb_whilo_i),
		.hi_i(wb_hi_i),
		.lo_i(wb_lo_i),
	
		//读端口1
		.hi_o(hi),
		.lo_o(lo)	
	);
	
	ctrl ctrl0(
		.rst(rst),
	
		.stallreq_from_id(stallreq_from_id),
	
  	//来自执行阶段的暂停请求
		.stallreq_from_ex(stallreq_from_ex),

		.stall(stall)       	
	);
	
	div div0(
		.clk(clk),
		.rst(rst),
	
		.signed_div_i(signed_div),
		.opdata1_i(div_opdata1),
		.opdata2_i(div_opdata2),
		.start_i(div_start),
		.annul_i(1'b0),
	
		.result_o(div_result),
		.ready_o(div_ready)
	);
	
endmodule