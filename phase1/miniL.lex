   /* CS152-Spring19 */
   /* A flex scanner specification for MINI-L language */


%{
   int currLine = 1, currPos = 1;
%}


%%
"function"	{currPos += yyleng; printf("FUNCTION\n");}
"beginparams"	{currPos += yyleng; printf("BEGIN_PARAMS\n");}
"endparams"	{currPos += yyleng; printf("END_PARAMS\n");}
"beginlocals"	{currPos += yyleng; printf("BEGIN_LOCALS\n");}
"endlocals"	{currPos += yyleng; printf("END_LOCALS\n");}
"beginbody"	{currPos += yyleng; printf("BEGIN_BODY\n");}
"endbody"	{currPos += yyleng; printf("END_BODY\n");}
"integer"	{currPos += yyleng; printf("INTEGER\n");}
"array"		{currPos += yyleng; printf("ARRAY\n");}
"of"		{currPos += yyleng; printf("OF\n");}
"if"		{currPos += yyleng; printf("IF\n");}
"then"		{currPos += yyleng; printf("THEN\n");}
"endif"		{currPos += yyleng; printf("ENDIF\n");}
"else"		{currPos += yyleng; printf("ELSE\n");}
"while"		{currPos += yyleng; printf("WHILE\n");}
"do"		{currPos += yyleng; printf("DO\n");}
"beginloop"	{currPos += yyleng; printf("BEGINLOOP\n");}
"endloop"	{currPos += yyleng; printf("ENDLOOP\n");}
"continue"	{currPos += yyleng; printf("CONTINUE\n");}
"read"		{currPos += yyleng; printf("READ\n");}
"write"		{currPos += yyleng; printf("WRITE\n");}
"and"		{currPos += yyleng; printf("AND\n");}
"or"		{currPos += yyleng; printf("OR\n");}
"not"		{currPos += yyleng; printf("NOT\n");}
"true"		{currPos += yyleng; printf("TRUE\n");}
"false"		{currPos += yyleng; printf("FALSE\n");}
"return"	{currPos += yyleng; printf("RETURN\n");}


"-"		{currPos += yyleng; printf("SUB\n");}
"+"		{currPos += yyleng; printf("ADD\n");}
"*"		{currPos += yyleng; printf("MULT\n");}
"/"		{currPos += yyleng; printf("DIV\n");}
"%"		{currPos += yyleng; printf("MOD\n");}


"=="		{currPos += yyleng; printf("EQ\n");}
"<>"		{currPos += yyleng; printf("NEQ\n");}
"<"		{currPos += yyleng; printf("LT\n");}
">"		{currPos += yyleng; printf("GT\n");}
"<="		{currPos += yyleng; printf("LTE\n");}
">="		{currPos += yyleng; printf("GTE\n");}


";"		{currPos += yyleng; printf("SEMICOLON\n");}
":"		{currPos += yyleng; printf("COLON\n");}
","		{currPos += yyleng; printf("COMMA\n");}
"("		{currPos += yyleng; printf("L_PAREN\n");}
")"		{currPos += yyleng; printf("R_PAREN\n");}
"["		{currPos += yyleng; printf("L_SQUARE_BRACKET\n");}
"]"		{currPos += yyleng; printf("R_SQUARE_BRACKET\n");}
":="		{currPos += yyleng; printf("ASSIGN\n");}

[ \t]+		{/* ignore spaces */ currPos += yyleng;}
"\n"		{currLine++; currPos = 1;}
##.*		{printf("");}

  (\.[0-9]+)|([0-9]+(\.[0-9]*)?([eE][+-]?[0-9]+)?)	{printf("NUMBER %s\n", yytext); currPos += yyleng;}
  [a-zA-Z]["_"a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z][a-zA-Z0-9]*	{printf("IDENT %s\n", yytext); currPos += yyleng;}

 /* Catch errors */
  .		{printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos, yytext); exit(0);}
  [0-9"_"]["_"a-zA-Z0-9]*	{printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currLine, currPos, yytext);exit(-1);}
  [a-zA-Z]["_"a-zA-Z0-9]*"_"+	{printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", currLine, currPos, yytext);exit(-1);}

%%

  
  
int main(int argc, char ** argv){
   if(argc >= 2){
      yyin = fopen(argv[1], "r");
      if(yyin == NULL){
         yyin = stdin;
      }
   }
   else{
      yyin = stdin;
   }

   yylex();
}

