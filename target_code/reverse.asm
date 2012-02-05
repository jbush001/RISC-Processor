#
#	Create and reverse a linked list
#

# struct list_node
# {
# 	list_node *next
# 	char value;
# }

_start			add		r29, r0, 1000
				add		r3, r0, 10
				call	_make_list
				add		r16, r2, 0
				add		r3, r16, 0
				call	_print_list
				add		r3, r16, 0
				call	_reverse_list
				add		r3, r2, 0
				call	_print_list
				halt

#
# Reverse linked list
#
# struct list_node reverse_list(struct list_node *list r3)
#{
#	struct list_node *new_list; r2
#	struct list_node *node; r7

_reverse_list	xor		r2, r2, r2		# new_list = NULL
rl_loop			beqz	r3, rl_done		# while (list) {
				add		r7, r3, 0		#    node = list
				loadw	r3, (r3)		#    list = list->next
				storew	r2, (r7)		#    node->next = new_list
				add		r2, r7, 0		#    new_list = node
				jump	rl_loop			# }
rl_done			jump	(link)

#
# Print a linked list
# void print_list(struct list_node *list);
#
_print_list		sub		sp, sp, 8
				storew	link, (sp)
				storew	r16, 4(sp)
				add		r16, r3, 0		# node = list
pl_loop			beqz	r16, pl_done	# while (node)
				loadb	r3, 4(r16)		#  print_char(node->value)
				call	_print_char
				loadw	r16, (r16)		# node = node->next
				jump	pl_loop
pl_done			add		r3, r0, 10
				call	_print_char
				loadw	link, (sp)
				loadw	r16, 4(sp)
				add		sp, sp, 8
				jump	(link)

#
# Allocate memory
# void *alloc(int size)
#
_alloc			loadw	r2, =heap_ptr
				add		r2, r2, r3		# return heap_ptr
				storew	r2, =heap_ptr	# heap_ptr += size
				jump	(link)

#
# struct list_node *make_list(int count)
#
_make_list		sub		sp, sp, 16
				storew	link, (sp)
				storew	r16, 4(sp)			# r16 = count
				storew	r17, 8(sp)			# r17 = head pointer (return value)
				storew	r18, 12(sp)			# r18 = current_node

				xor		r17, r17, r17
				xor		r18, r18, r18
				add		r16, r3, 0			# stash count
ml_loop			add		r3, r0, 8			# alloc(sizeof(struct list_node))
				call	_alloc
				bnez	r17, head_set		# Is this the first node in the list?
				add		r17, r2, 0			# stash head pointer
				jump	head_not_set
head_set		storew	r2, (r18)			# current_node->next = allocated_node
head_not_set	add		r18, r2, 0			# current_node = allocated node
				add		r7, r16, ('a' - 1)
				storeb	r7, 4(r18)			# current_node->value = blah
				sub		r16, r16, 1			# decrement count
				bnez	r16, ml_loop		# loop		
				storew	r0, (r18)			# current_node->next = NULL
				add		r2, r17, 0			# return value

				loadw	r18, 12(sp)
				loadw	r17, 8(sp)
				loadw	r16, 4(sp)
				loadw	link, (sp)
				add		sp, sp, 16
				jump	(link)

# void print_char(char value);
_print_char		loadw	r7, =ser_addr			# Get address of serial port
				storeb	r3, (r7)				# Print value
				jump	(link)
ser_addr		.long	0xa0000000


heap_ptr		.long 	heap_start
heap_start		.long	0
