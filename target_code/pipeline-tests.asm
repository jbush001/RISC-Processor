

						########### Test conditional branches  #############
						add		r2, r0, 1
						nop
						nop
						nop
						beqz	r2, fail
						bnez	r2, test1
						jump	fail
test1					xor		r2, r2, r2	
						nop
						nop
						nop
						beqz	r2, test2
						jump	fail
						bnez	r2, fail
test2

						# Test that R0 is always zero, even when results are forwarded
						add		r0, r0, 1234
						add		r1, r0, 0
						add		r2, r0, 0
						add		r3, r0, 0
						bnez	r0, fail
						bnez	r1, fail
						bnez	r2, fail
						bnez	r3, fail

						# Test that PC works correctly in arithmetic
						add		r1, pc, 0		# operand 1
						sub		r1, r1, .
						bnez	r1, fail
						add		r1, r0, pc		# operand 2
						sub		r1, r1, .
						bnez	r1, fail

						################## Test arithmetic #######################
						# Add immediate
						add		r2, r0, 0x1234
						add		r3, r0, 0x1234
						add		r4, r0, 0x4567
						add		r5, r0, 2
						
						# Add register
						add		r6, r3, r4
						sub		r1, r6, 0x579b	# check
						bnez	r1, fail

						# Subtract immediate
						sub		r1, r2, 0x1234
						bnez	r1, fail
						sub		r1, r3, 0x1000
						beqz	r1, fail
						sub		r1, r1, 0x234
						bnez	r1, fail

						# Subtract register
						sub		r1, r2, r3
						bnez	r1, fail		# Equal
						sub		r1, r2, r4
						beqz	r1, fail		# Not Equal

						# AND immediate
						and		r1, r3, 0x4567		# 0x1234 & 0x4567 = 0x24
						sub		r1, r1, 0x24
						bnez	r1, fail

						# AND register
						and		r1, r3, r4
						sub		r1, r1, 0x24
						bnez	r1, fail
						
						# OR immediate
						or		r1, r3, 0x4567
						sub		r1, r1, 0x5777
						bnez	r1, fail
						
						# OR register
						or		r1, r3, r4
						sub		r1, r1, 0x5777
						bnez	r1, fail
						
						# XOR immediate
						xor		r1, r3, r4
						sub		r1, r1, 0x5753
						bnez	r1, fail
						
						# XOR register
						xor		r1, r3, 0x4567
						sub		r1, r1, 0x5753
						bnez	r1, fail

						# LSL immediate
						lsl		r1, r3, 2
						sub		r1, r1, 0x48d0 
						bnez	r1, fail
						
						# LSL register
						lsl		r1, r3, r5
						sub		r1, r1, 0x48d0
						bnez	r1, fail
						
						# LSR immediate
						lsl		r6, r2, 19		# Set leftmost bit
						lsr		r1, r6, 19		# Shift right
						sub		r1, r1, 0x1234
						bnez	r1, fail
						
						# LSR register
						add 	r5, r0, 19
						lsl		r6, r2, 19		# Set leftmost bit
						lsr		r1, r6, r5		# Shift right
						sub		r1, r1, 0x1234
						bnez	r1, fail
						
						# ASR immediate (with sign extend)
						lsl		r6, r2, 19		# Set leftmost bit
						asr		r1, r6, 19		# Shift right
						sub		r1, r1, 0xf234	# Sign extended to fffff234
						bnez	r1, fail

						# ASR immediate w/o sign extend
						lsl		r6, r2, 18		# Don't Set leftmost bit
						asr		r1, r6, 18		# Shift right
						sub		r1, r1, 0x1234
						bnez	r1, fail
						
						# ASR register (with sign)
						add		r7, r0, 19
						lsl		r6, r2, r7		# Set leftmost bit
						asr		r1, r6, r7		# Shift right
						sub		r1, r1, 0xf234	# Sign extended to fffff234
						bnez	r1, fail

						# ASR register (w/o sign)
						add		r7, r0, 18
						lsl		r6, r2, r7		# Don't Set leftmost bit
						asr		r1, r6, r7		# Shift right
						sub		r1, r1, 0x1234
						bnez	r1, fail
						
						# SLT immediate
						slt		r1, r2, 0x1234
						bnez	r1, fail
						slt		r1, r3, 0x4567
						beqz	r1, fail
						slt		r1, r4, 0x1234
						bnez	r1, fail

						# SLT register
						slt		r1, r2, r3
						bnez	r1, fail
						slt		r1, r3, r4
						beqz	r1, fail
						slt		r1, r4, r3
						bnez	r1, fail
						
						# SGT immediate
						sgt		r1, r2, 0x1234
						bnez	r1, fail
						sgt		r1, r3, 0x4567
						bnez	r1, fail
						sgt		r1, r4, 0x1234
						beqz	r1, fail
						
						# SGT register
						sgt		r1, r2, r3
						bnez	r1, fail
						sgt		r1, r3, r4
						bnez	r1, fail
						sgt		r1, r4, r3
						beqz	r1, fail


						############# Test RAW hazard (bypassing) ##############
						# op1
						add		r2, r0, 0x6789
						add		r3, r0, r2			# One cycle delay (exu)
						add		r4, r0, r2			# Two cycle delay (mau)
						add		r5, r0, r2			# Three cycle delay (wbu)
						
						sub		r1, r3, 0x6789		# check 1
						bnez	r1, fail	
						sub		r1, r4, 0x6789		# check 2
						bnez	r1, fail
						sub		r1, r5, 0x6789		# check 3
						bnez	r1, fail

						# op2
						add		r2, r0, 0x6bcd
						add		r6, r2, r0			# One cycle delay (exu)
						add		r7, r2, r0			# Two cycle delay (mau)
						add		r8, r2, r0			# Three cycle delay (wbu)
						
						sub		r1, r6, 0x6bcd			# check 1
						bnez	r1, fail	
						sub		r1, r7, 0x6bcd			# check 2
						bnez	r1, fail
						sub		r1, r8, 0x6bcd			# check 3
						bnez	r1, fail

						####################  Memory tests ######################
						# RAW hazard on op3 (store data) register forwarding
						add		r1, r0, 0x6ace
						add		r2, =memtest
						storew	r1, (r2)			# One cycle delay (exu)
						storew	r1, 4(r2)			# Two cycle delay (mau)
						storew	r1, 8(r2)			# Three cycle delay (wbu)
						nop
						nop
						nop
						loadw	r9, (r2)
						loadw	r10, 4(r2)
						loadw	r11, 8(r2)
						sub		r1, r9, 0x6ace			# check 1
						bnez	r1, fail	
						sub		r1, r10, 0x6ace			# check 2
						bnez	r1, fail
						sub		r1, r11, 0x6ace			# check 3
						bnez	r1, fail
						
						# Ensure pc works properly as a store target
						add		r1, =memtest
						add		r3, r0, . + 8
						storew	pc, (r1)
						loadw	r2, (r1)
						sub		r2, r2, r3
						bnez	r2, fail
						
						# Test memory access hazards
						# RAW memory hazard
						add		r1, r0, 0x6eef
						add		r2, =memtest
						storew	r1, (r2)
						loadw	r3, (r2)		
						add		r4, r0, r3			# One cycle delay (exu)
						add		r5, r0, r3			# Two cycle delay (mau)
						add		r6, r0, r3			# Three cycle delay (wbu)
						sub		r1, r4, 0x6eef
						bnez	r1, fail
						sub		r1, r5, 0x6eef
						bnez	r1, fail
						sub		r1, r6, 0x6eef
						bnez	r1, fail

						# WAR hazard
						add		r4, r0, 0x1eed
						loadw	r3, (r2)
						storew	r4, 4(r2)	 	# Write after read interlock
						loadw	r5, 4(r2)
						sub		r1, r5, r4		# Check
						bnez	r1, fail

						# Read alignment/sizes
						add		r4, =readarray
						
						# Read signed short, offset 0
						loads	r3, (r4)
						sub		r3, r3, 0x8765	# Will sign extend to 0xffff8765
						bnez	r3, fail

						# Read signed short, offset 2
						loads	r3, 2(r4)
						sub		r3, r3, 0x4321
						bnez	r3, fail

						# Read unsigned short, offset 0
						loadsu	r3, (r4)
						lsr		r1, r3, 16
						bnez	r1, fail			# check that high bits are unset
						xor		r1, r3, 0x8765
						lsl		r1, r1, 16			# Clear out top bits
						lsr		r1, r1, 16
						bnez	r1, fail


						# Read signed byte, offset 0
						loadb	r3, (r4)
						sub		r3, r3, 0xff87	# Will sign extend to 0xffffff87
						bnez	r3, fail

						# Read signed byte, offset 1
						loadb	r3, 1(r4)
						sub		r3, r3, 0x65
						bnez	r3, fail

						# Read signed byte, offset 2						
						loadb	r3, 2(r4)
						sub		r3, r3, 0x43
						bnez	r3, fail

						# Read signed byte, offset 3
						loadb	r3, 3(r4)
						sub		r3, r3, 0x21
						bnez	r3, fail

						# Read unsigned byte, offset 0
						loadbu	r3, (r4)
						sub		r3, r3, 0x87
						bnez	r3, fail

						# Write alignment/sizes
						# Write short, offset 0
						add		r5, =writearray1
						add		r3, r0, 0x1234
						stores	r3, (r5)

						loadw	r4, (r5)
						lsl		r1, r4, 16			# Low word
						lsr		r1, r1, 16
						bnez	r1, fail
						lsr		r1, r4, 16			# High word
						sub		r1, r1, 0x1234
						bnez	r1, fail

						# Write short, offset 1						
						add		r5, =writearray2
						stores	r3, 2(r5)

						loadw	r1, (r5)
						sub		r1, r1, 0x1234
						bnez	r1, fail

						# Write byte, offset 0
						add		r5, =writearray3
						add		r3, r0, 0x12
						storeb	r3, (r5)
						loadw	r4, (r5)
						lsl		r1, r4, 16			# Strip leading bits	
						lsr		r1, r1, 16
						bnez	r1, fail
						lsr		r1, r4, 16			# High word
						sub		r1, r1, 0x1200
						bnez	r1, fail

						# Write byte, offset 1
						add		r5, =writearray4
						storeb	r3, 1(r5)
						loadw	r4, (r5)
						lsl		r1, r4, 16			# Strip leading bits	
						lsr		r1, r1, 16
						bnez	r1, fail
						lsr		r1, r4, 16			# High word
						sub		r1, r1, 0x0012
						bnez	r1, fail

						# Write byte, offset 2
						add		r5, =writearray5
						storeb	r3, 2(r5)
						loadw	r4, (r5)
						lsl		r1, r4, 16			# Strip leading bits	
						lsr		r1, r1, 16
						sub		r1, r1, 0x1200
						bnez	r1, fail
						lsr		r1, r4, 16			# High word
						bnez	r1, fail

						# Write byte, offset 3
						add		r5, =writearray6
						storeb	r3, 3(r5)
						loadw	r4, (r5)
						lsl		r1, r4, 16			# Strip leading bits	
						lsr		r1, r1, 16
						sub		r1, r1, 0x0012
						bnez	r1, fail
						lsr		r1, r4, 16			# High word
						bnez	r1, fail

						# Test a load directly into PC
						loadw	pc, =indirectjump
						jump	fail		# Falls through if above fails
jumplabel

						# Test call
						call	calllabel1
retaddr1				jump	fail
						nop
						nop
						nop
						nop
						nop
calllabel1				add		r1, =retaddr1
						sub		r1, r1, link		# Ensure link register was set correctly
						bnez	r1, fail		
					

						# Test call through a register
						add		r1, =calllabel2
						call	(r1)
retaddr2				nop
						nop
						nop
						nop
						nop
						nop
						nop
calllabel2				add		r1, =retaddr2
						sub		r1, r1, link
						bnez	r1, fail


pass					loadw	r1, =seraddr
						add		r2, r0, 'P'
						storeb	r2, (r1)
						halt

fail					loadw	r1, =seraddr
						add		r2, r0, 'F'
						storeb	r2, (r1)
						halt

seraddr					.long	0xa0000000
memtest					.long	0, 0, 0, 0
readarray				.long 	0x87654321
writearray1				.long	0
writearray2				.long	0
writearray3				.long 	0
writearray4				.long 	0
writearray5				.long 	0
writearray6				.long 	0
writearray7				.long 	0
indirectjump			.long	jumplabel

