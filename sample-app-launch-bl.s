  .syntax unified
  .cpu cortex-m0plus
  .fpu softvfp
  .thumb

  .section .text.Reset_Handler
  .weak Reset_Handler
  .type Reset_Handler, %function
Reset_Handler:
    CPSID  i                // disable IRQs
    LDR     R0, =0x20000200
    MOV     SP, R0
    LDR   r0, =0xE000ED08   // SCB->VTOR register
    LDR   r1, =0x1FFF0000   // new vector table base (embedded bootloader VTOR)
    STR   r1, [r0]          // write VTOR
    LDR   r0, =0x1FFF00C1   // jump target (function after setting the VTOR on the embedded bootloader)
    BX    r0

.size Reset_Handler, .-Reset_Handler

   .section .isr_vector,"a",%progbits
  .type g_pfnVectors, %object
  .size g_pfnVectors, .-g_pfnVectors


g_pfnVectors:
  .word   0x20002000      /* placeholder stack top */
  .word  Reset_Handler                  /* Reset Handler */
  .word  0                    /* NMI Handler */
  .word  0              /* Hard Fault Handler */
  .word  0                              /* Reserved */
  .word  0                              /* Reserved */
  .word  0                              /* Reserved */
  .word  0                              /* Reserved */
  .word  0                              /* Reserved */
  .word  0                              /* Reserved */
  .word  0                              /* Reserved */
  .word  0                    /* SVCall Handler */
  .word  0                              /* Reserved */
  .word  0                              /* Reserved */
  .word  0                 /* PendSV Handler */
  .word  0                /* SysTick Handler */
  .word  0                              /* 0Reserved */
  .word  0                              /* 1Reserved */
  .word  0                              /* 2Reserved */
  .word  0               /* 3FLASH */
  .word  0                 /* 4RCC */
  .word  0             /* 5EXTI Line 0 and 1 */
  .word  0             /* 6EXTI Line 2 and 3 */
  .word  0            /* 7EXTI Line 4 to 15 */

  
