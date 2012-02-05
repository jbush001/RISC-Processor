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


interrupt					sub		sp, sp, 12
							storew	r1, 0(r29)
							storew	r2, 4(r29)

							loadw	r1, =seraddr
							add		r2, r0, 'B'
							storeb	r2, (r1)
							add		r2, r0, 10
							storeb	r2, (r1)

							# restore stack and return
							add		sp, sp, 12
							loadw	r1, -12(r29)
							loadw	r2, -8(r29)
							rfi

seraddr						.long	0xa0000000
