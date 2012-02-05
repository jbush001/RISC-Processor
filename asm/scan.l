
%%


\n						{line_num++;}
[ \t]					{}
\#[^\n]*				{}
r[0-9]+					{ yylval.intval = atoi(yytext + 1); return TOK_REG; }
cr[0-9]+				{ yylval.intval = atoi(yytext + 2); return TOK_CONTROL_REG; }
sp						{ yylval.intval = 29; return TOK_REG; }
link					{ yylval.intval = 30; return TOK_REG; }
pc						{ yylval.intval = 31; return TOK_REG; }

halt					{ return TOK_HALT; }
add						{ yylval.mnemonic = 0; return TOK_MNEMONIC; }	// Offset into opcode table
sub						{ yylval.mnemonic = 1; return TOK_MNEMONIC; }
and						{ yylval.mnemonic = 2; return TOK_MNEMONIC; }
or						{ yylval.mnemonic = 3; return TOK_MNEMONIC; }
xor						{ yylval.mnemonic = 4; return TOK_MNEMONIC; }
lsl						{ yylval.mnemonic = 5; return TOK_MNEMONIC; }
lsr						{ yylval.mnemonic = 6; return TOK_MNEMONIC; }
asr						{ yylval.mnemonic = 7; return TOK_MNEMONIC; }
loadw					{ yylval.mnemonic = 8; return TOK_MNEMONIC; }
loads					{ yylval.mnemonic = 9; return TOK_MNEMONIC; }
loadsu					{ yylval.mnemonic = 10; return TOK_MNEMONIC; }
loadb					{ yylval.mnemonic = 11; return TOK_MNEMONIC; }
loadbu					{ yylval.mnemonic = 12; return TOK_MNEMONIC; }
storew					{ yylval.mnemonic = 13; return TOK_MNEMONIC; }
stores					{ yylval.mnemonic = 14; return TOK_MNEMONIC; }
storeb					{ yylval.mnemonic = 15; return TOK_MNEMONIC; }
slt						{ yylval.mnemonic = 16; return TOK_MNEMONIC; }
sgt						{ yylval.mnemonic = 17; return TOK_MNEMONIC; }
rdctl					{ return TOK_RDCTL; }
wrctl					{ return TOK_WRCTL; }
beqz					{ return TOK_BEQZ; }
bnez					{ return TOK_BNEZ; }
jump					{ return TOK_JUMP; }
call					{ return TOK_CALL; }
nop						{ return TOK_NOP; }
move					{ return TOK_MOVE; }
rfi						{ return TOK_RFI; }

\.include				{ return TOK_INCLUDE; }
\.segment				{ return TOK_SEGMENT; }
\.byte					{ return TOK_DB; }
\.short					{ return TOK_DH; }
\.long					{ return TOK_DL; }
\.string				{ return TOK_DS; }
\.space					{ return TOK_SPACE; }
\.align					{ return TOK_ALIGN; }
equ						{ return TOK_EQU; }

">>"					{ return TOK_RSHIFT; }
"<<"					{ return TOK_LSHIFT; }
0x[0-9A-Fa-f]+			{ yylval.intval = strtoll(yytext, NULL, 16); return TOK_LITERAL; }
\-[0-9]+				{ yylval.intval = -atoi(yytext + 1); return TOK_LITERAL; }
[0-9]+					{ yylval.intval = atoi(yytext); return TOK_LITERAL; }
[\+\-\*/\(\),\=&|\~\^\.] { return yytext[0]; }


[a-zA-Z0-9_]+			{ 
							symbol *sym = find_symbol(yytext);
							if (sym == NULL)
								sym = add_symbol(yytext, SYM_UNKNOWN, 0);

							yylval.sym = sym;
							if (sym->type == SYM_CONSTANT)
								return TOK_CONSTANT;
							else
								return TOK_LABEL;
						}

\"[^\"]*\"				{ unescape_string(yylval.strval, yytext + 1); yylval.strval[strlen(yylval.strval) - 1] = '\0'; return TOK_STRING; }
\'[^\']\'				{ yylval.intval = yytext[1]; return TOK_LITERAL; }

