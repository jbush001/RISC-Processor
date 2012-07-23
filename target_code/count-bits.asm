; 
; Copyright 2008-2012 Jeff Bush
; 
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; 
;     http://www.apache.org/licenses/LICENSE-2.0
; 
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
; 



start				add		sp, r0, 1000	# Set up stack
					
					loadw	r1, =input
					call 	count_bits1
					add		r2, =result		# Compute effective address of result array
 					call	dec2ascii
 					add		r1, =result
 					call	print_string

					loadw	r1, =input
					call 	count_bits2
					add		r2, =result		# Compute effective address of result array
 					call	dec2ascii
 					add		r1, =result
 					call	print_string


input				.long 0xcafe0123

# r1 = word to count bits in
# r2 = total bit count
# r3 temp
count_bits1			xor		r2, r2, r2
loopn1				beqz	r1, donen1
					sub		r3, r1, 1
					and		r1, r1, r3		# r1 &= r1 - 1
					add		r2, r2, 1
					jump	loopn1
donen1				add		r1, r2, 0
					move	pc, link


count_bits2			xor		r2, r2, r2
loopn2				beqz	r1, donen2
					and		r3, r1, 0xf		# Get this bit pattern
					lsl		r3, r3, 2		# Multiply by 4 to get table offset
					add		r4, =bit_count_lookup	# Get table base address
					add		r3, r3, r4		# Add offset
					loadw	r4, (r3)		# Load table entry
					add		r2, r2, r4		# Add to total bit count
					lsr		r1, r1, 4		# Shift out bits
					jump	loopn2			# Loop and get more
donen2				add		r1, r2, 0		# Transfer to r1
					move	pc, link
					
					
					.include "utils.inc"

bit_count_lookup	.long  0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4
result				.byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
					
