/* calculator. */
%{
 #include <stdio.h>
 #include <stdlib.h>
 void yyerror(const char *msg);
 extern int currLine;
 extern int currPos;
 FILE * yyin;
%}

%union{
  int ival;
  char *string;
  char character;
}

%error-verbose
%token	FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY OF IF THEN ENDIF ELSE WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE RETURN AND OR NOT TRUE FALSE SUB ADD MULT DIV MOD EQ NEQ LT GT LTE GTE SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN NUMBER IDENT
%type	<ival>		NUMBER
%type	<string>	IDENT
%right 			ASSIGN 
/*%precedence 		OR */
%left 			AND 
%right 			NOT 
%left 			LT GT LTE GTE EQ NEQ 
%left 			'-' '+'
%left 			'*' '/' '%'
/*%precedence		NEG /* negation--unary minus */
%right 			'^' /* exponentiation */
%left 			'(' ')' 


%%
prog_start:
			functions {printf("prog_start -> functions\n");}
			;

functions:
			function functions {printf("functions -> function functions\n");}
			| {printf("functions -> epsilon\n");}
			;
function:
			FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY {printf("function -> FUNCTION IDENT SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY\n");}
			;

declarations:
			declaration SEMICOLON declarations {printf("declarations -> declaration SEMICOLON declarations\n");}
			| {printf("declarations -> epsilon\n");}
			;
declaration: 
			identifiers COLON INTEGER {printf("declaration -> identifiers COLON INTEGER\n");}
			| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {printf("declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER\n");}
			;

identifiers:
			ident {printf("identifiers -> ident\n");}
			| ident COMMA identifiers {printf("identifiers ->ident COMMA identifiers\n");}
			;

ident:
			IDENT {printf("ident -> IDENT %s \n", $1);}
			;

statements:
			statement SEMICOLON statements {printf("statements -> statement SEMICOLON statements\n");}
			| {printf("statements -> epsilon\n");}
			;
statement:
			var ASSIGN expression {printf("statement -> var ASSIGN expression\n");}
                        | if
                        | while
                        | do
                        | read
                        | write
                        | CONTINUE {printf("statements -> CONTINUE\n");}
                        | RETURN expression {printf("statements -> RETURN expression\n");} 
                        ;

if:
			IF bool_exp THEN statements else ENDIF {printf("statements -> IF bool_exp THEN statement else ENDIF\n");}
			;

else:
			ELSE statements {printf("else -> ELSE statement\n");}
			| {printf("else -> epsilon\n");}
			;

while:
			WHILE bool_exp BEGINLOOP statements ENDLOOP {printf("statements -> WHILE bool_exp BEGINLOOP statement ENDLOOP\n");}
			;

do:
			DO BEGINLOOP statements ENDLOOP WHILE bool_exp {printf("statements -> DO BEGINLOOP statement ENDLOOP WHILE bool_exp\n");}
			;

read:
			READ vars {printf("statement -> READ vars\n");}
			;

write:
			WRITE vars {printf("statement -> WRITE vars\n");}
			;

vars:
			var {printf("vars -> var\n");}
			| var COMMA vars {printf("vars -> var COMMA vars\n");}
			; 

var: 
			ident {printf("var -> IDENT\n");}
			| ident L_SQUARE_BRACKET expressions R_SQUARE_BRACKET {printf("var -> IDENT L_SQUARE_BRACKET expressions R_SQUARE_BRACKET\n");}
			;

bool_exp:
			relation_and_exp {printf("bool_exp -> relation_and_exp\n");}
			| relation_and_exp OR bool_exp {printf("bool_exp -> relation_and_exp OR relation_and_exp\n");}
			;
relation_and_exp:
			relation_exp {printf("relation_and_exp -> relation_exp\n");}
			| relation_exp AND relation_and_exp {printf("relation_and_exp -> relation_exp AND relation_exp");}
			;
relation_exp: 
			relation_exp1 {}
			| NOT relation_exp1 {}
			;
relation_exp1:
			expression comp expression {printf("relation_exp -> expression comp expression\n");}
			| TRUE {printf("relation_exp -> TRUE\n");}
			| FALSE {printf("relation_exp -> FALSE\n");}
			| L_PAREN bool_exp R_PAREN {printf("relation_exp -> L_PAREN bool_exp R_PAREN\n");}
			;

comp:
			EQ {printf("comp -> EQ\n");}
                        | NEQ {printf("comp -> NEQ\n");}
                        | LT {printf("comp -> LT\n");}
                        | GT {printf("comp -> GT\n");}
                        | LTE {printf("comp -> LTE\n");}
                        | GTE {printf("comp -> GTE\n");}
                        ;
expressions:
			expression {printf("expressions -> expression\n");}
			| expression COMMA expression {printf("expressions -> expression COMMA expression\n");}
			;
			
expression:
			mult_expression {printf("expression -> mult_expression\n");}
			| mult_expression ADD expression {printf("expression -> mult_expression ADD mult_expression\n");}
                        | mult_expression SUB expression {printf("expression -> mult_expression SUB mult_expression\n");}
                        ;

mult_expression:	
			term
                        | term MULT mult_expression {printf("mult_expression -> term MULT term\n");} 
                        | term DIV mult_expression {printf("mult_expression -> term DIV term\n");}
                        | term MOD mult_expression {printf("mult_expression -> term MOD term\n");}
			;

term: //not done
			SUB term1
			| term1
                        | ident L_PAREN expressions R_PAREN{printf("mult_expression -> term MULT term\n");} 
			;

term1:
			var {printf("term -> var\n");}
			| NUMBER {printf("term -> NUMBER\n");}
			| L_PAREN expression R_PAREN {printf("term -> L_PAREN expression R_PAREN\n");}
			;

%%

int main(int argc, char **argv) {
   if (argc > 1) {
      yyin = fopen(argv[1], "r");
      if (yyin == NULL){
         printf("syntax: %s filename\n", argv[0]);
      }//end if
   }//end if
   yyparse(); // Calls yylex() for tokens.
   return 0;
}

void yyerror(const char *msg) {
   printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}



