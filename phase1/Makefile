parse: miniL.lex
	flex miniL.lex
	gcc -o lexer lex.yy.c -lfl

clean:
	rm -f lex.yy.c lexer
