
# Print a string
# r1 = string to print
print_string		sub		sp, sp, 16
					storew	link, 0(sp)
					storew	r1, 4(sp)
					storew	r2, 8(sp)
					storew	r3, 12(sp)
					loadw	r3, =ser_addr			# Get address of serial port
char_loop			loadbu	r2, (r1)
					beqz	r2, str_done
					add		r1, r1, 1
					storeb	r2, (r3)
					jump	char_loop
str_done			xor		r2, r2, r2
					add		r2, r2, 10
					storeb	r2, (r3)				# Print carriage return
					loadw	r3, 12(sp)				# epilogue
					loadw	r2, 8(sp)
					loadw	r1, 4(sp)
					loadw	link, (sp)
					add		sp, sp, 16
					jump	(link)
ser_addr			.long	0xa0000000


# Convert decimal to ascii
#  r1 = decimal value
#  r2 = string to copy into
#
dec2ascii			sub		sp, sp, 4
					storew	link, 0(sp)
					move	r4, r2			# stash beginning of string in r4
					move	r3, r2			# Use r3 for current string pointer
cloop				xor		r2, r2, r2
					add		r2, r2, 10		# Radix
					call	udiv
					add		r2, r2, '0'		# Convert to ascii
					storeb	r2, (r3)		# Store it
					add		r3, r3, 1		# Increment pointer
					bnez	r1, cloop
					
					xor		r2, r2, r2		# null terminate string
					storeb	r2, (r3)
					sub		r3, r3, 1

					# Digits are reversed, need to swap them
swap_loop			sgt		r5, r4, r3
					bnez	r5, swap_done
					loadbu	r5, (r4)
					loadbu	r6, (r3)
					storeb	r5, (r3)
					storeb	r6, (r4)
					add		r4, r4, 1
					sub		r3, r3, 1
					jump	swap_loop
swap_done			loadw	link, 0(sp)
					add		sp, sp, 4
					jump	(link)

#
#	Unsigned divide
#	Entry: r1 = dividend, r2 = divisor
#	Exit: r1 = quotient, r2 = divisor
#
#
udiv				sub		sp, sp, 24
					storew	link, 0(sp)
					storew	r3, 4(sp)		# r3 = quotient
					storew	r4, 8(sp)		# r4 = scratchpad
					storew	r5, 12(sp)		# r5 = highest bit of dividend
					storew	r6, 16(sp)		# r6 = highest bit of divisor
					storew	r7, 20(sp)		# r7 = number of bits in quotient
				
					slt		r4, r1, r2		# Is dividend less than divisor?
					beqz	r4, skip1
					
					# Yes, result is zero
					move	r2, r1			# remainder is dividend
					xor 	r1, r1, r1
					jump	div_done

skip1				xor		r3, r3, r3		# Set quotient to zero

					# Find highest bit of dividend
					xor		r5, r5, r5		# r5 = 0
					add		r5, r5, 31		# r5 = 31
loop1				lsr		r4, r1, r5		# get nth bit
					and		r4, r4, 1		# Mask
					bnez	r4, foundit1	# is it 1?
					sub		r5, r5, 1
					jump	loop1

					# Find the highest bit of the divisor/remainder
foundit1			move	r6, r5			# Since the divisor is less than the dividend, start there
loop2				lsr		r4, r2, r6
					and		r4, r4, 1
					bnez	r4, foundit2
					sub		r6, r6, 1
					jump	loop2

					# Shift the remainder so it is aligned with the divisor
foundit2			sub		r7, r5, r6
					lsl		r2, r2, r7
					add		r7, r7, 1
loop3				lsl		r3, r3, 1		# Shift quotient left
					slt		r4, r1, r2
					bnez	r4, notgreater
					or		r3, r3, 1		# set least significant bit
					sub		r1, r1, r2		# Subtract remainder from dividend
notgreater			lsr		r2, r2, 1		# Shift remainder one bit to the right
					sub		r7, r7, 1		# decrement bit count
					bnez	r7, loop3		# Loop until finished
					
					move	r2, r1			# Move remainder into r2
					move	r1, r3			# Move quotient into r1
					
div_done			loadw	link, 0(sp)
					loadw	r3, 4(sp)
					loadw	r4, 8(sp)
					loadw	r5, 12(sp)
					loadw	r6, 16(sp)
					loadw	r7, 20(sp)
					add		sp, sp, 24
					jump	(link)