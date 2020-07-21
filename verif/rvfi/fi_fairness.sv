
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
input wire          imem_recv       ,
input wire          imem_ack        ,
input wire          imem_error      ,

input wire          dmem_req        ,
input wire          dmem_gnt        ,
input wire          dmem_recv       ,
input wire          dmem_ack        ,
input wire          dmem_error       

);

//
// The maximum number of outstanding memory requests which can be
// in flight before the formal stimulus *must* give a response.
parameter MAX_OUTSTANDING_MEM_REQUESTS = 3;

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
wire [31:0] n_imem_rsps = imem_rsps + (imem_recv && imem_ack);

reg [31:0] dmem_reqs;
reg [31:0] dmem_rsps;

wire [31:0] n_dmem_reqs = dmem_reqs + (dmem_req  && dmem_gnt);
wire [31:0] n_dmem_rsps = dmem_rsps + (dmem_recv && dmem_ack);

reg  [31:0] imem_outstanding;
wire [31:0] n_imem_outstanding = imem_outstanding + (imem_reqs > imem_rsps);

reg  [31:0] dmem_outstanding;
wire [31:0] n_dmem_outstanding = dmem_outstanding + (dmem_reqs > dmem_rsps);

// Instruction memory request/response counter.
always @(posedge clock) begin
    if(reset) begin
        imem_reqs <= 0;
        imem_rsps <= 0;
    end else begin
        imem_reqs <= n_imem_reqs;
        imem_rsps <= n_imem_rsps;
    end
end

// Time for which there is >0 outstanding instruction memory requests.
always @(posedge clock) begin
    if(reset || imem_reqs <= imem_rsps) begin
        imem_outstanding <= 0;
    end else begin
        imem_outstanding <= n_imem_outstanding;
    end
end

// Time for which there is >0 outstanding data memory requests.
always @(posedge clock) begin
    if(reset || dmem_reqs <= dmem_rsps) begin
        dmem_outstanding <= 0;
    end else begin
        dmem_outstanding <= n_dmem_outstanding;
    end
end

// Data memory request/response counter.
always @(posedge clock) begin
    if(reset) begin
        dmem_reqs <= 0;
        dmem_rsps <= 0;
    end else begin
        dmem_reqs <= n_dmem_reqs;
        dmem_rsps <= n_dmem_rsps;
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
// Don't allow memory requests to "back up" without being acknowledged.
// Maximum of N cycles spent with outstanding requests.
always @(posedge clock) begin
    restrict(imem_outstanding <= MAX_OUTSTANDING_MEM_REQUESTS);
    restrict(dmem_outstanding <= MAX_OUTSTANDING_MEM_REQUESTS);
end

//
// Fairness restrictions so we never get a memory response we
// didn't issue a request for.
always @(posedge clock) begin
    restrict(dmem_rsps <= dmem_reqs);
    restrict(imem_rsps <= imem_reqs);

    // If num responses >= num requests, *mem_recv is clear. Else True.
    restrict(dmem_rsps >= dmem_reqs ? dmem_recv == 1'b0 : 1'b1);
    restrict(imem_rsps >= imem_reqs ? imem_recv == 1'b0 : 1'b1);
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
    if(imem_recv) begin
        assume(imem_error == 1'b0);
    end
    if(dmem_recv) begin
        assume(dmem_error == 1'b0);
    end
end


endmodule
