MEMORY {
    FLASH (rx)   : ORIGIN = 0x08000000, LENGTH = 0x100000 /* 1M   */
    RAM (rwx)    : ORIGIN = 0x20000000, LENGTH = 0x20000  /* 128K */
    CCMRAM (rwx) : ORIGIN = 0x10000000, LENGTH = 0x10000  /* 64K  */
}
