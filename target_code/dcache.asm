

_start					add		r7, r0, 0xa000
						lsl		r7, r7, 16

						# Store A
						add		r3, r0, 512
						add		r4, =stringa
						add		r5, r0, 32
						call	_memcpy
						
						# Store B on an aliased cache line
						add		r3, r0, 512 + 0x2000
						add		r4, =stringb
						add		r5, r0, 32
						call	_memcpy
						
						# Read back A
						add		r3, r0, 512
						add		r4, r0, 32
						call	_write_string
						
						add		r8, r0, 10		# print CR
						storeb	r8, (r7)
						
						# Read back B
						add		r3, r0, 512 + 0x2000
						add		r4, r0, 32
						call	_write_string


						add		r8, r0, 10		# print CR
						storeb	r8, (r7)
						
						halt

stringa					.string	"0123456789abcdef987654321gfedcba"
stringb					.string "!@#$%^&*()QAZWSXEDCRFVTGBYHNUJMK"

#
# memcpy(void *dest, const void *src, int count)
#
_memcpy					beqz	r5, mc_done
						loadb	r7, (r4)
						add		r4, r4, 1
						storeb	r7, (r3)
						add		r3, r3, 1
						sub		r5, r5, 1
						jump	_memcpy
mc_done					jump	(link)


#
# write_string(const void *string, int length)
#
_write_string			add		r7, r0, 0xa000
						lsl		r7, r7, 16
ws_loop					beqz	r4, ws_done
						loadb	r8, (r3)
						storeb	r8, (r7)
						add		r3, r3, 1
						sub		r4, r4, 1
						jump	ws_loop
ws_done					jump	(link)
						

