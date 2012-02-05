

SER_ADDR		equ	0xA0000000

				.segment "text"

				add		sp, r0, 1000		# set stack

				add		r1, =test_str		# Get address of hello str
				call	bubblesort
				add		r1, =test_str		# Get address of hello str
				call 	print_string
				halt

# r1 = pointer to array of chars (null terminated)
# r2 = changed
# r3 = current pointer
# r4 = first character
# r5 = second character
# r6 = comparison result
bubblesort		xor		r2, r2, r2		# changed = 0
				add 	r3, r1, 0		# stash current pointer
loop			loadb 	r4, 0(r3)
				loadb 	r5, 1(r3)
				beqz 	r5, loop_exit
				slt 	r6, r5, r4		# r6 = r4 < r5
				beqz 	r6, loop_tail	# Loop if there is no need to swap
				storeb 	r5, 0(r3)		# Swap
				storeb 	r4, 1(r3)
				or		r2, r2, 1		# changed = 1
loop_tail		add		r3, r3, 1
				jump	loop


loop_exit		bnez	r2, bubblesort	# If we swapped anything, run again
				add 	pc, link, 0


# r1 = string to print
# r2 = character
# r3 = serial port address
print_string	sub		sp, sp, 16
				storew	link, 0(sp)
				storew	r1, 4(sp)
				storew	r2, 8(sp)
				storew	r3, 12(sp)
				loadw	r3, =ser_addr		# Get address of serial port
char_loop		loadbu	r2, 0(r1)
				beqz	r2, str_done
				add		r1, r1, 1
				storeb	r2, 0(r3)
				jump	char_loop
str_done		xor		r2, r2, r2
				add		r2, r2, 10
				storeb	r2, 0(r3)				# Print carriage return
				loadw	r3, 12(sp)				# epilogue
				loadw	r2, 8(sp)
				loadw	r1, 4(sp)
				loadw	link, 0(sp)
				add		sp, sp, 16
				add		pc, link, 0
ser_addr		.long	SER_ADDR

				
test_str		.string	"qfsaceribdtuvjpoyxnghklwmz"


