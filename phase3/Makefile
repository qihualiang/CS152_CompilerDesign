parse: miniL.lex miniL.y
	bison -v -d --file-prefix=y miniL.y
	flex miniL.lex
	g++ -o parser y.tab.c lex.yy.c -lfl --std=c++11

clean:
	rm -f lex.yy.c y.tab.* y.output *.o parser
