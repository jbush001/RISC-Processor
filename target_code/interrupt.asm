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
