`timescale 1ns/1ps
`define CYCLE      100.0
`define End_CYCLE  1000000      // Modify cycle times once your design need more cycle times!
`define TOTAL_DATA 38
`define TEST_DATA  2


module testbench;

//===============================================================
//==== signal declaration =======================================
    // ----------------------------------------------------------
    // -------- singals in top module ---------------------------
    reg  clk;
    reg  reset;
	reg  clk_25;
    reg avm_m0_waitrequest;
    wire [31:0] avm_m0_address; //
    wire avm_m0_read; //
    wire avm_m0_write; //
	reg [255:0] avm_m0_readdata;
	wire [255:0] avm_m0_writedata;//
	reg avm_m0_readdatavalid; 
	 
	wire avs_s0_waitrequest;
	reg avs_s0_address;
	reg avs_s0_read;
	reg avs_s0_write;
	wire [7:0] avs_s0_readdata;
	reg [7:0] avs_s0_writedata;
	reg [255:0] temp_readdata;

    // -------- input data & output golden pattern --------------
    reg [255:0] dn_mem [0:1];
    reg [255:0] c_mem [0:`TOTAL_DATA-1];
    reg [255:0] m_mem [0:`TOTAL_DATA-1];
    initial $readmemh("./DE5_PCIe_avalon_rsa_sim/dat/dn.dat", dn_mem);
    initial $readmemh("./DE5_PCIe_avalon_rsa_sim/dat/c.dat", c_mem);
    initial $readmemh("./DE5_PCIe_avalon_rsa_sim/dat/m.dat", m_mem);

    // -------- variables &indices ------------------------------
    integer i, j;

//==== module connection ========================================
    avalon_rsa top(
    .clk(clk),
    .reset(reset),
	.clk_25(clk_25),
    
	//avalon_MM_m0
	.avm_m0_waitrequest(avm_m0_waitrequest),
	.avm_m0_address(avm_m0_address),
	.avm_m0_read(avm_m0_read),
	.avm_m0_write(avm_m0_write),
	.avm_m0_readdata(avm_m0_readdata),
	.avm_m0_writedata(avm_m0_writedata),
	.avm_m0_readdatavalid(avm_m0_readdatavalid),

	//avalon_MM_s0 => flag register
	.avs_s0_waitrequest(avs_s0_waitrequest),
	.avs_s0_address(avs_s0_address),
	.avs_s0_read(avs_s0_read),
	.avs_s0_write(avs_s0_write),
	.avs_s0_readdata(avs_s0_readdata),
	.avs_s0_writedata(avs_s0_writedata)
	);

//==== create waveform file =====================================
    initial begin
        $fsdbDumpfile("exp2_rsa.fsdb");
        $fsdbDumpvars;
    end

//==== start simulation =========================================
    
    always begin 
        #(`CYCLE/2) clk = ~clk; 
    end
	always begin 
        #(`CYCLE) clk_25 = ~clk_25; 
    end
    
    initial begin
        #0; // t = 0
        clk     = 1'b1;
		clk_25 = 1'b0;
        reset   = 1'b0; 
        avm_m0_waitrequest      = 1'b0;
        avm_m0_readdata      	= 8'b0;
        avs_s0_address   		= 1'b0;
        avs_s0_read			 	= 1'd0;
        avs_s0_write		    = 1'd0;
        avs_s0_writedata		= 8'd1;
		avm_m0_readdatavalid	= 1'd0;

        #(`CYCLE) reset = 1'b1; // t = 1
        #(`CYCLE) reset = 1'b0; // t = 2
        
        #(0.001);
		
		#(`CYCLE) avs_s0_write = 1'b1;// t = 3
        #(`CYCLE) avs_s0_write = 1'b0;// t = 4
		#(`CYCLE);
        // a3 & a2
        while(avs_s0_readdata == 8'b11111111) begin
            if(avm_m0_read==1) begin
				if(avm_m0_address<32'd32) begin
					temp_readdata = dn_mem[0];
					#(`CYCLE);
					avm_m0_waitrequest = 1'b1;
					#(`CYCLE*3);
					avm_m0_waitrequest = 1'b0;
					#(`CYCLE);
					avm_m0_readdatavalid = 1;
					avm_m0_readdata = temp_readdata;
					#(`CYCLE);
					avm_m0_readdatavalid = 0;
				end
				else if(avm_m0_address<32'd64) begin
					temp_readdata = dn_mem[1];
					#(`CYCLE);
					avm_m0_waitrequest = 1'b1;
					#(`CYCLE*3);
					avm_m0_waitrequest = 1'b0;
					#(`CYCLE);
					avm_m0_readdatavalid = 1;
					avm_m0_readdata = temp_readdata;
					#(`CYCLE);
					avm_m0_readdatavalid = 0;
				end
				else begin
					temp_readdata = c_mem[(avm_m0_address-32'd64)/32];
					#(`CYCLE);
					avm_m0_waitrequest = 1'b1;
					#(`CYCLE*3);
					avm_m0_waitrequest = 1'b0;
					#(`CYCLE);
					avm_m0_readdatavalid = 1;
					avm_m0_readdata = temp_readdata;
					#(`CYCLE);
					avm_m0_readdatavalid = 0;
				end
            end
            else if(avm_m0_write==1) begin
					
					//avm_m0_waitrequest = 1'b1;
					//#(`CYCLE*3);
					//avm_m0_waitrequest = 1'b0;
					#(`CYCLE);
                //if(avm_m0_writedata !== m_mem[(avm_m0_address-32'd64)/32][(avm_m0_address-32'd64)*8 +: 8]) begin
                    $display("-----------------------------------------------------\n");
                    $display("output %h !== expect %h \n",avm_m0_writedata, m_mem[(avm_m0_address-32'd64)/32]);
                    $display("-----------------------------------------------------\n");
                    //#1;
                    //$finish;'
                end
			else begin
				#(`CYCLE);
            end
        end
	end
//==== Terminate the simulation, FAIL ===========================
    initial  begin
        #(`CYCLE*`End_CYCLE);
        $display("-----------------------------------------------------\n");
        $display("Error!!! Somethings' wrong with your code ...!!\n");
        $display("-------------------------FAIL------------------------\n");
        $finish;
    end

endmodule
