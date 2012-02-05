
# r29 = stack

				add		sp, r0, 1000		# set stack
				add		r1, r0, 8
				call	fib
				call	print_hex
				halt

# r1 = n.  r1 = return value
# r2, r3, r4 = temporaries
fib				sub		sp, sp, 16
				storew	link, (sp)
				storew	r2, 4(sp)
				storew	r3, 8(sp)
				storew	r4, 12(sp)
				
				bnez	r1, not_zero
				jump	epilogue		# fib(0) = 0
not_zero		sub		r2, r1, 1
				bnez	r2, not_one		
				jump	epilogue		# fib(1) = 1
				
not_one			sub 	r1, r1, 1		# return fib(n - 1, n - 2)
				add		r3, r1, 0
				call	fib
				add		r4, r1, 0
				sub 	r1, r3, 1
				call	fib
				add		r1, r4, r1
				
epilogue		loadw	link, (sp)
				loadw	r2, 4(sp)
				loadw	r3, 8(sp)
				loadw	r4, 12(sp)
				add		sp, sp, 16
				move	pc, link


# r1 = digit value				
# r2 = word value
# r3 = temporary
print_hex		sub		sp, sp, 4
				storew	link, (sp)
				move	r2, r1

looptop			lsr		r1, r2, 28
				and		r1, r1, 0xf
				sgt		r3, r1, 9
				bnez	r3, isAlpha
				add		r1, r1, '0'
				call	print_char
				jump 	loopbot
isAlpha			add		r1, r1, 'A' - 10
				call	print_char
loopbot			lsl		r2, r2, 4
				bnez	r2, looptop

				loadw	link, (sp)
				add		sp, sp, 4
				move	pc, link

# r1 = character to print
print_char		sub		sp, sp, 4
				storew	r3, (sp)
				loadw	r3, =ser_addr
				storeb	r1, (r3)
				loadw	r3, (sp)
				add		sp, sp, 4
				move	pc, link
				

ser_addr		.long	0xA0000000

				
				
				
