#
# struct task
# {
#      task *next;
#      unsigned int sp;
# };
#


							jump	start
							jump	interrupt
start						add		r29, r0, 1000		# Set up stack

							# Enable interrupts
							add		r1, r0, 1
							wrctl	cr0, r1

							loadw	r1, =seraddr
loop1						add		r2, r0, 'A'
							storeb	r2, (r1)
							add		r2, r0, 10
							storeb	r2, (r1)
							jump	loop1


interrupt					sub		sp, sp, 120		# Allocate space for the entire iframe
							storew	r1, 0(r29)
							storew	r2, 4(r29)
							storew	r3, 8(r29)
							storew	r4, 12(r29)
							storew	r5, 16(r29)
							storew	r6, 20(r29)
							storew	r7, 24(r29)
							storew	r8, 28(r29)
							storew	r9, 32(r29)
							storew	r10, 36(r29)
							storew	r11, 40(r29)
							storew	r12, 44(r29)
							storew	r13, 48(r29)
							storew	r14, 52(r29)
							storew	r15, 56(r29)
							storew	r16, 60(r29)
							storew	r17, 64(r29)
							storew	r18, 68(r29)
							storew	r19, 72(r29)
							storew	r20, 76(r29)
							storew	r21, 80(r29)
							storew	r22, 84(r29)
							storew	r23, 88(r29)
							storew	r24, 92(r29)
							storew	r25, 96(r29)
							storew	r26, 100(r29)
							storew	r27, 104(r29)
							storew	r28, 108(r29)
							# Skipped stack pointer
							storew	r30, 112(r29)
							rdctl	r1, cr1			# Get PC
							storew	r1, 116(r29)	# Store in iframe

							loadw	r1, =current_task	# Get current task pointer
							storew	r29, 4(r1)			# Stash it 

						



							#
							# Return path
							#
							loadw	r1, 116(r29)	# Load PC from iframe
							wrctl	cr1, r1			# Store in control register
							
							# restore stack
							add		sp, sp, 120
							
							# Reload registers
							loadw	r1, -120(r29)
							loadw	r2, -116(r29)
							loadw	r3, -112(r29)
							loadw	r4, -108(r29)
							loadw	r5, -104(r29)
							loadw	r6, -100(r29)
							loadw	r7, -96(r29)
							loadw	r8, -92(r29)
							loadw	r9, -88(r29)
							loadw	r10, -84(r29)
							loadw	r11, -80(r29)
							loadw	r12, -76(r29)
							loadw	r13, -72(r29)
							loadw	r14, -68(r29)
							loadw	r15, -64(r29)
							loadw	r16, -60(r29)
							loadw	r17, -56(r29)
							loadw	r18, -52(r29)
							loadw	r19, -48(r29)
							loadw	r20, -44(r29)
							loadw	r21, -40(r29)
							loadw	r22, -36(r29)
							loadw	r23, -32(r29)
							loadw	r24, -28(r29)
							loadw	r25, -24(r29)
							loadw	r26, -20(r29)
							loadw	r27, -16(r29)
							loadw	r28, -12(r29)
							# Skipped stack pointer
							loadw	r30, -8(r29)
							rfi

seraddr						.long	0xa0000000
current_task				.long	0
