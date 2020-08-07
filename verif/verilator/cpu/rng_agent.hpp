
#include <queue>

#ifndef RNG_AGENT_HPP
#define RNG_AGENT_HPP

//! Stores responses to be sent back to the CPU.
typedef struct {
    uint32_t data;
    uint8_t  status;
} rng_agent_txn ;

extern const uint8_t rng_op_seed;
extern const uint8_t rng_op_samp;
extern const uint8_t rng_op_test;

extern const uint8_t rng_status_noinit        ;
extern const uint8_t rng_status_init_unhealthy;
extern const uint8_t rng_status_init_healthy  ;

/*!
@brief Acts as monitor and driver to the randomness interface of the CPU.
*/
class rng_agent {

public:

    /*!
    @brief Create a new agent with pointers to the signals it will control.
    */
    rng_agent(
        uint8_t  * rng_req_valid    , //!< Signal a new request to the RNG
        uint8_t  * rng_req_op       , //!< Operation to perform on the RNG
        uint32_t * rng_req_data     , //!< Suplementary seed/init data
        uint8_t  * rng_req_ready    , //!< RNG accepts request
        uint8_t  * rng_rsp_valid    , //!< RNG response data valid
        uint8_t  * rng_rsp_status   , //!< RNG status
        uint32_t * rng_rsp_data     , //!< RNG response / sample data.
        uint8_t  * rng_rsp_ready      //!< CPU accepts response.
    ){
        this -> rng_req_valid  = rng_req_valid ;
        this -> rng_req_op     = rng_req_op    ;
        this -> rng_req_data   = rng_req_data  ;
        this -> rng_req_ready  = rng_req_ready ;
        this -> rng_rsp_valid  = rng_rsp_valid ;
        this -> rng_rsp_status = rng_rsp_status;
        this -> rng_rsp_data   = rng_rsp_data  ;
        this -> rng_rsp_ready  = rng_rsp_ready ;
    };

    //! Put the interface in reset
    void set_reset();
    
    //! Take the interface out of reset
    void clear_reset();
    
    //! Compute any *next* signal values
    void posedge_clk();

    //! Drive any signal updates
    void drive_signals();
        
    // Wires driven / monitored by the agent.
    uint8_t  * rng_req_valid    ; //!< Signal a new request to the RNG
    uint8_t  * rng_req_op       ; //!< Operation to perform on the RNG
    uint32_t * rng_req_data     ; //!< Suplementary seed/init data
    uint8_t  * rng_req_ready    ; //!< RNG accepts request
    uint8_t  * rng_rsp_valid    ; //!< RNG response data valid
    uint8_t  * rng_rsp_status   ; //!< RNG status
    uint32_t * rng_rsp_data     ; //!< RNG response / sample data.
    uint8_t  * rng_rsp_ready    ; //!< CPU accepts response.

    //! Maximum length of a stalled request.
    uint32_t   max_req_stall = 5;

    //! Maximum length of a stalled response.
    uint32_t   max_rsp_stall = 5;

    //! Get the current status of the RNG
    uint8_t    get_status();

    //! Sample a new value from the RNG
    uint32_t   rng_sample();
    
    //! Seed the RNG.
    void       rng_seed  (uint32_t seed);

protected:

    // Current status of the RNG
    uint8_t    status           ;

    //! Current request stall length.
    uint32_t   req_stall_len = 0;

    //! Current response stall length.
    uint32_t   rsp_stall_len = 0;
    
    uint8_t    n_rng_req_ready  ; //!< Next RNG accepts request
    uint8_t    n_rng_rsp_valid  ; //!< Next RNG response data valid
    uint8_t    n_rng_rsp_status ; //!< Next RNG status
    uint32_t   n_rng_rsp_data   ; //!< Next RNG response / sample data.
    
    //! Response queue
    std::queue<rng_agent_txn *> rsp_q;
    
    uint8_t rand_chance(int a, int b) {
        return ((rand() % b) < a) ? 1 : 0;
    }

};


#endif
