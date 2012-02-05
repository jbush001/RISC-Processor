
LINE_LENGTH		equ		72
PATTERN_LENGTH	equ		89

_start			add		r29, r0, 1000
				call	_chargen
#				add		r3, =pattern
#				add		r4, r0, 5
#				call	_write_chars
				halt

#
# void write_char(char value)
#
_write_char		loadw	r7, =seraddr			# Get address of serial port
				storeb	r3, (r7)				# Print value
				jump	(link)
seraddr			.long 0xa0000000


#
# void write_chars(const char *data, int length)
#
_write_chars	loadw	r8, =seraddr
				add		r7, r4, 7		# (count + 7) / 8
				lsr		r7, r7, 3		
				add		r10, =switch_lookup
				and		r11, r4, 7		# mask bits
				lsl		r11, r11, 2		# multiply by 4 to find table address
				add		r10, r10, r11
				loadw	pc, (r10)
case0			loadb	r9, (r3)		
				add		r3, r3, 1
				storeb	r9, (r8)
case7			loadb	r9, (r3)
				add		r3, r3, 1
				storeb	r9, (r8)
case6			loadb	r9, (r3)
				add		r3, r3, 1
				storeb	r9, (r8)
case5			loadb	r9, (r3)
				add		r3, r3, 1
				storeb	r9, (r8)
case4			loadb	r9, (r3)
				add		r3, r3, 1
				storeb	r9, (r8)
case3			loadb	r9, (r3)
				add		r3, r3, 1
				storeb	r9, (r8)
case2			loadb	r9, (r3)
				add		r3, r3, 1
				storeb	r9, (r8)
case1			loadb	r9, (r3)
				add		r3, r3, 1
				storeb	r9, (r8)
				sub		r7, r7, 1
				bnez	r7, case0
				jump	(link)
switch_lookup	.long case0, case1, case2, case3, case4, case5, case6, case7	

#
# void chargen(void)
#
# r16 pattern offset
#
_chargen		xor		r16, r16, r16
				add		r16, r0, (PATTERN_LENGTH - LINE_LENGTH + 1)

				# Does this pattern wrap?
loop0			add		r7, r16, LINE_LENGTH		# r7 = current_offset + LINE_LENGTH
				sgt 	r1, r7, PATTERN_LENGTH		# if (r7 > PATTERN_LENGTH)
				bnez	r1, split
not_split		add		r3, =pattern
				add		r3, r3, r16					# data = pattern offset
				add		r4, r0, LINE_LENGTH			# length = LINE_LENGTH
				call	_write_chars				# write chars
				jump	split_check_done
split			add		r4, r0, PATTERN_LENGTH		# Determine length before wrap
				sub		r4, r4, r16
				add		r17, r0, LINE_LENGTH		# Determine length of remainder
				sub		r17, r17, r4				# Stash it in r17
				add		r3, =pattern
				add		r3, r3, r16					# data = pattern offset
				call	_write_chars
				add		r3, =pattern				# data = start of data
				add		r4, r0, r17					# length = saved remainder
				call	_write_chars	
split_check_done add	r3, r0, 10
				call	_write_char
				add	r16, r16, 1
				sub		r1, r16, PATTERN_LENGTH		# Have we exceeded pattern length
				bnez	r1, loop0					# no, so loop
				xor		r16, r16, r16				# yes, reset it to zero
				jump	loop0						# ...and loop

pattern			.string "!#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz"
