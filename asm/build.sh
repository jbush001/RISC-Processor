# 
# Copyright 2008-2012 Jeff Bush
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

#!/bin/sh

if [ ! -d OBJ ];
then
	mkdir OBJ
fi

flex -o OBJ/_scan.c scan.l
bison -o OBJ/_assemble.c assemble.y
gcc -g OBJ/_assemble.c symbol_table.c output_file.c -o asm

