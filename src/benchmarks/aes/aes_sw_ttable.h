
#ifndef __AES_TTABLE_COMMON__
#define __AES_TTABLE_COMMON__

#define ROTR32(x,c) (((x) >> (c)) | ((x) << (32 - (c))))

#define U8_TO_U32LE(x) (((uint32_t)((x)[3]) << 24) | \
                        ((uint32_t)((x)[2]) << 16) | \
                        ((uint32_t)((x)[1]) <<  8) | \
                        ((uint32_t)((x)[0]) <<  0) )


#define U32_TO_U8LE(r,x,i) {                   \
  (r)[ (i) + 0 ] = ( (x) >>  0 ) & 0xFF;       \
  (r)[ (i) + 1 ] = ( (x) >>  8 ) & 0xFF;       \
  (r)[ (i) + 2 ] = ( (x) >> 16 ) & 0xFF;       \
  (r)[ (i) + 3 ] = ( (x) >> 24 ) & 0xFF;       \
}

extern uint32_t AES_ENC_TBOX_0[];
extern uint32_t AES_ENC_TBOX_1[];
extern uint32_t AES_ENC_TBOX_2[];
extern uint32_t AES_ENC_TBOX_3[];
extern uint32_t AES_ENC_TBOX_4[];

#endif

