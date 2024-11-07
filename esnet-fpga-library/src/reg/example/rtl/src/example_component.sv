// -----------------------------------------------------------------------------
// example_component
//
// This module represents a fully-functional example of a logic component
// containing a register block for software control/monitoring.
//
// The register block and associated interfaces are described in the
// `example_reg_blk.yaml` specification, at example/reg.
//
// From this yaml description, the regio tool is used to autogenerate a number
// of SystemVerilog source files describing the register block and associated
// application interface. The regio tool is automatically invoked by the Make
// infrastructure, resulting in the following source files being generated
// (at example/reg/src/):
//
//    * example_reg_pkg.sv:
//
//         Definitions package describing parameters, types and structs
//         describing register offsets, register formats, field packing, etc.
//
//    * example_reg_blk.sv:
//
//         Module description describing register block. Contains all of the
//         registers as defined in the example.yaml specification, as well
//         as local address decoding and data mux/demux functions.
//
//    * example_reg_intf.sv:
//
//         Interface description representing a set of signals that can be used
//         by the application logic to interact with the register file.
//
// The example_component module describes how these autogenerated source
// objects get instantiated and interconnected.
// -----------------------------------------------------------------------------

module example_component
#(
) (
    // Component (datapath) clock
    input  logic clk,

    // AXI4-Lite control (upstream) interface
    //
    // NOTE: assumption here is that AXI clock (axil_if.clk) is synchronous to
    //       the component clock (clk); if not, appropriate synchronization is
    //       required.
    axi4l_intf.peripheral  axil_if,

    // Input
    input  logic           input_valid,
    input  logic [31:0]    input_data,

    // Output
    output logic           output_valid,
    output logic [31:0]    output_data
);
    // -------------------------------------------------------------------------
    // Register package import
    //
    // This imports the auto-generated register package into the local
    // namespace, providing access to definitions, types and structs describing
    // register offsets, register formats, field packing, etc.
    //
    //  Access to register properties is provided by name (rather than
    //  hard-coded or magic values).  This allows the application code to be
    //  written against a (stable) abstract representation of the register file
    //  and greatly improves the readability, maintainability and extensibility
    //  of the design.
    //
    // -------------------------------------------------------------------------
    import example_reg_pkg::*;

    // -------------------------------------------------------------------------
    // Register block application interface
    //
    // The auto-generated application register interface is
    // instantiated here. This interface provides local access to all of
    // the registers defined in the example.yaml specification.
    //
    // The specific signaling available for a given register depends on the
    // specified access mode.
    // NOTE: the signals provided by the interface are included based on the
    //       access provided to the application logic. Sometimes this is a bit
    //       tricky since the access mode is specified (in the yaml description)
    //       from the perspective of the access provided to software:
    //   e.g. the application logic has read+write access to Read-Only (ro)
    //        registers but read-only access to Read-Write (rw) registers
    //        (rw registers are writeable by software only).
    //   e.g. event notification signaling is only present for wr_evt/rd_evt
    //        access modes.
    // -------------------------------------------------------------------------
    example_reg_intf example_reg_if ();

    // -------------------------------------------------------------------------
    // Register block instantiation
    //
    // The auto-generated register block module is instantiated here.
    // This module contains all of the registers as defined in the
    // example.yaml specification, as well as local address decoding
    // and data mux/demux functions.
    //
    // Upstream/control/software access to the registers is provided
    // by the (standard) AXI-L interface
    //
    // Downstream/application/hardware access to the registers is provided
    // by the (block-specific) example_reg_if interface.
    // -------------------------------------------------------------------------
    example_reg_blk i_example_reg_blk (
        .axil_if     (axil_if),
        .reg_blk_if  (example_reg_if)
    );

    // -------------------------------------------------------------------------
    // Local signal declarations
    //
    // Some local signals, declared using the register data types imported
    // from the autogenerated example_reg_pkg definitions package:
    // -------------------------------------------------------------------------

    // 1. Declare a signal using the type defined for  the `rw_example` register
    reg_rw_example_t rw_example;

    // 2. Declare a signal using the type defined for the `field0` field of the
    //    `rw_example` register
    fld_rw_example_field0_t rw_example_field0;

    // 3. Declare a signal using the type defined for the `field1` field of the
    //    `rw_example` register. This time, the package is explicitly named:
    example_reg_pkg::fld_rw_example_field1_t rw_example_field1;

    // -------------------------------------------------------------------------
    // Register interface connections
    //
    // Some examples of connections between the application logic and the
    // register interface:
    // -------------------------------------------------------------------------

    // 1. Assign rw_example register value to intermediate value
    //
    //    Read-Write registers can be written by software such that the value
    //    can be used by the application logic.
    //    Here the register value is assigned to an intermediate value:
    assign rw_example = example_reg_if.rw_example;
    //    And here the field0 value is assigned from the intermediate value:
    assign rw_example_field_0 = rw_example.field0;
    //    And here the field1 value is assigned from the interface directly:
    assign rw_example_field_1 = example_reg_if.rw_example.field1;

    // 2. Assign static value into ro_example register
    //
    //    Read-only registers are updated by the application using a simple
    //    data/valid interface. The register is updated (synchronously) whenever
    //    the `*_nxt_v` update valid signal is asserted.
    //    In this case, we have a static value, so drive the valid signal to
    //    static 1'b1:
    assign example_reg_if.ro_example_nxt_v = 1'b1;
    // - Set the static register value by field:
    assign example_reg_if.ro_example_nxt = '{field0: 8'hAB, field1: RO_EXAMPLE_FIELD1_XYZ};

    // 3. Assign dynamic value into ro_monolithic_example register
    //
    //    In this case, we have a dynamic value. The ro_monolithic_example
    //    register is updated to input_data when input_valid is asserted.
    assign example_reg_if.ro_monolithic_example_nxt_v = input_valid;
    // - Set the static register value by field:
    assign example_reg_if.ro_monolithic_example_nxt = input_data;

    // 4. Drive data + valid using wr_evt_example register.
    //
    //    Write-Event (wr_evt) registers can be written and read by software,
    //    (similar to the `rw` register type) with the value available to the
    //    application logic. In addition, when the register is written, an
    //    'event' or 'notify' pulse is launched.
    //
    //    Here, the output_data port is driven from the wr_evt_example register
    //    value:
    assign output_data = example_reg_if.wr_evt_example;
    //    And the output_valid is driven from the associated write event:
    assign output_valid = example_reg_if.wr_evt_example_wr_evt;

    // 5. Implement clear-on-read counter using rd_evt_example register
    //
    //    Read-Event (rd_evt) registers are updated by the application logic
    //    (similar to the `ro` register type) be read by software. In addition,
    //    when the register is read, an 'event' or 'notify' pulse is launched.
    //
    //    Here, a clear-on-read counter is implemented:
    logic        clr;
    logic [31:0] count;
    
    assign clr = example_reg_if.rd_evt_example_rd_evt;

    initial count = 0;
    always @(posedge clk) begin
        if (clr) count <= 0;
        else     count <= count + 1;
    end

    assign example_reg_if.rd_evt_example_nxt_v = 1'b1;
    assign example_reg_if.rd_evt_example_nxt = count;

    // -------------------------------------------------------------------------
    // Application logic
    //
    // Some examples of how the register values can be referenced, set or
    // otherwise used in an application:
    // -------------------------------------------------------------------------

    //  Example of how enumerated type field could be used:
    logic assert_abc, error;
    always_comb begin
        assert_abc = 1'b0;
        error = 1'b0;
        case (example_reg_if.rw_example.field1)
            RW_EXAMPLE_FIELD1_ABC: assert_abc = 1'b1;
            RW_EXAMPLE_FIELD1_XYZ: assert_abc = 1'b0;
            default:               error      = 1'b1;
        endcase
    end

endmodule : example_component
