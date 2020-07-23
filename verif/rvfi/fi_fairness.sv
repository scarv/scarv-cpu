
//
// module: fi_fairness
//
//  A set of trackers and assumptions/restrictions which make sure that
//  any formal stimulus engine "plays fair".
//
module fi_fairness (

input wire          clock           ,
input wire          reset           ,

input wire          int_nmi         ,
input wire          int_mtime       ,
input wire          int_external    ,
input wire          int_software    ,

input wire          imem_req        ,
input wire          imem_gnt        ,
input wire          imem_error      ,

input wire          dmem_req        ,
input wire          dmem_gnt        ,
input wire          dmem_error       

);

//
// The maximum number of cycles a request can be outstanding for before
// the formal simulus *must* accept the request.
parameter MAX_MEM_REQUEST_STALL        = 3;


//
// Memory request/response counters
// --------------------------------------------------------------------

reg [31:0] imem_reqs;
reg [31:0] imem_rsps;
        
wire [31:0] n_imem_reqs = imem_reqs + (imem_req  && imem_gnt);

reg [31:0] dmem_reqs;
reg [31:0] dmem_rsps;

wire [31:0] n_dmem_reqs = dmem_reqs + (dmem_req  && dmem_gnt);

// Instruction memory request/response counter.
always @(posedge clock) begin
    if(reset) begin
        imem_reqs <= 0;
    end else begin
        imem_reqs <= n_imem_reqs;
    end
end

// Data memory request/response counter.
always @(posedge clock) begin
    if(reset) begin
        dmem_reqs <= 0;
    end else begin
        dmem_reqs <= n_dmem_reqs;
    end
end

// Instruction memory request grant stall counter.
reg  [4:0] imem_req_gnt_stall;
wire [4:0] n_imem_req_gnt_stall = imem_req_gnt_stall + (imem_req&&!imem_gnt);

always @(posedge clock) begin
    if(reset || imem_gnt) begin
        imem_req_gnt_stall <= 0;
    end else begin
        imem_req_gnt_stall <= n_imem_req_gnt_stall;
    end
end


// Data memory request grant stall counter.
reg  [4:0] dmem_req_gnt_stall;
wire [4:0] n_dmem_req_gnt_stall = dmem_req_gnt_stall + (dmem_req&&!dmem_gnt);


always @(posedge clock) begin
    if(reset || dmem_gnt) begin
        dmem_req_gnt_stall <= 0;
    end else begin
        dmem_req_gnt_stall <= n_dmem_req_gnt_stall;
    end
end


//
// Fairness restrictions
// --------------------------------------------------------------------

//
// Don't allow memory *requests* to be ignored for more than N cycles.
always @(posedge clock) begin
    restrict(imem_req_gnt_stall < MAX_MEM_REQUEST_STALL);
    restrict(dmem_req_gnt_stall < MAX_MEM_REQUEST_STALL);
end


//
// Assume we never get non-maskable interrutps.
// TODO: Proper interrupt checking for RVFI
always @(posedge clock) begin
    assume(int_nmi      == 1'b0);
    assume(int_mtime    == 1'b0);
    assume(int_external == 1'b0);
    assume(int_software == 1'b0);
end

//
// RVFI can't handle propagation of bus errors properly, so assume
// they don't happen. *gulp*.
always @(posedge clock) begin
    if($past(imem_req && imem_gnt)) begin
        assume(imem_error == 1'b0);
    end
    if($past(dmem_req && dmem_gnt)) begin
        assume(dmem_error == 1'b0);
    end
end


endmodule
