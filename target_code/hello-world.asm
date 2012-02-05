#
# Hello World
#

				.segment "text"

start			add		r1, =hellostr		# Get address of hello str
				loadw	r3, =ser_addr		# Get address of serial port
char_loop		loadbu	r2, (r1)
				beqz	r2, done
				storeb	r2, (r3)
				add		r1, r1, 1
				jump	char_loop
done			halt

ser_addr		.long	0xA0000000
hellostr		.string "Hello World"
