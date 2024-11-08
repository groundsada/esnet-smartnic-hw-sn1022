module xilinx_ram_sdp_lutram_wrapper #(
    parameter int ADDR_WID = 8,
    parameter int DATA_WID = 113
)(
    input  logic                 wr_clk,
    input  logic                 wr_en,
    input  logic                 wr_req,
    input  logic [ADDR_WID-1:0]  wr_addr,
    input  logic [DATA_WID-1:0]  wr_data,

    input  logic                 rd_clk,
    input  logic                 rd_srst,
    input  logic                 rd_en,
    input  logic  [ADDR_WID-1:0] rd_addr,
    output logic  [DATA_WID-1:0] rd_data
);

    xilinx_ram_sdp_lutram #(
        .ADDR_WID ( ADDR_WID ),
        .DATA_WID ( DATA_WID )
    ) i_xilinx_ram_sdp_lutram (
        .*
    );

endmodule : xilinx_ram_sdp_lutram_wrapper
