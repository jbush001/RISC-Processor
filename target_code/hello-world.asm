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
