%{
 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include <assert.h>

 #include <vector>
 #include <string>
 #include <sstream>
 #include <iostream>

 using namespace std;
 
 int yylex(void);
 void yyerror(const char *msg);
 extern int currLine;
 extern int currPos;
 extern FILE * yyin;

  
 vector<string> varTable;
 vector<string> varTableType;
 vector<string> paramTable;
 vector<string> opTable;
 vector<string> opTableType;
 vector<string> toPrint; //lines to be print in ONE fucntion
 vector<string> toPrintAll; //lines to be print in ALL fucntions


 vector<string> functions;

 vector<vector<string> > if_label;
 vector<vector<string> > loop_label;

 int labelCount = 0;
 int varCount = 0;
 int tempCount = 0;
 int paramCount = 0;

 bool isParam = false;
 bool findMain = false;
 bool findError = false;
 bool idUsed (string s) {
	for (unsigned i = 0; i < varTable.size(); i++) {
		if (varTable[i] == s) {
			return true;
		}
	}
	for (unsigned i = 0; i < paramTable.size(); i++) {
		if (paramTable[i] == s) {
			return true;
		}
	}
	for (unsigned i = 0; i < functions.size(); i++) {
		if (functions[i] == s) {
			return true;
		}
	}
	return false;
 }

%}

%union{
  int ival;
  char *string;
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
			functions
			;

functions:
			function functions 
			| /* epsilon */
			;
function:
			FUNCTION IDENT {functions.push_back($2);} SEMICOLON BEGIN_PARAMS {isParam = true;} declarations END_PARAMS printParams BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY 	
			{
				toPrintAll.push_back(string("func ") + functions.back());
				// print varTable
				for(unsigned i = 0; i < varTable.size(); i++) {
					if(varTableType[i] == "INT") {
						toPrintAll.push_back(". " + varTable[i]);
					}
					else {
						toPrintAll.push_back(".[] " + varTable[i] + ", " + varTableType[i]);
					}
				}

				toPrintAll.push_back(": START");

				// print toPrint
				for(unsigned i = 0; i < toPrint.size(); i++) {
					toPrintAll.push_back(toPrint[i]);
				}

				//clear tables
				varTable.clear();
				varTableType.clear();
				opTable.clear();
				opTableType.clear();
				paramTable.clear();
				toPrint.clear();

				toPrintAll.push_back("endfunc");
			}
			;

printParams:
			{
				 while(!paramTable.empty()) {
				 	toPrint.push_back("= " + paramTable.back() + ", $" + to_string(paramCount)); 
				 	paramTable.pop_back(); 
				 	paramCount++;
				 } 
				 isParam = false;
			}
			;

declarations:
			declaration SEMICOLON declarations
			| /* epsilon */
			;
declaration: 
			identifiers COLON INTEGER {
				varTableType.push_back("INT");
			}
			| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER {
				varTableType.push_back(to_string($5));
			}
			;

identifiers:
			IDENT {
				if (idUsed($1)) {
					yyerror("identifier has been declared!");
					findError = true;
				}
				varTable.push_back($1);
				if (isParam) {
					paramTable.push_back($1);
				}
			}
			| IDENT COMMA identifiers {
				if (idUsed($1)) {
					yyerror("identifier has been declared!");
					findError = true;
				}
				varTable.push_back($1);
				varTableType.push_back("INT");
				// push multiple “INT” except for the last one
				// last “INT” is pushed by “declaration”
			}
			;


statements:
			statement SEMICOLON statements 
			| /* epsilon */
			;
statement:
			assign
			| if_bool THEN statements ENDIF {
				toPrint.push_back(": " + if_label.back()[1]);
				if_label.pop_back();
			}
			| if_bool THEN statements if_else ENDIF {
				toPrint.push_back(": " + if_label.back()[2]);
				if_label.pop_back();
			}
			| while_bool statements ENDLOOP { // while loop
				toPrint.push_back(":= " + loop_label.back()[1]);
				toPrint.push_back(": " + loop_label.back()[3]);
				loop_label.pop_back();
			}
			| do_loop WHILE bool_exp { // do loop
				toPrint.push_back("?:= " + loop_label.back()[1] + ", " + opTable.back());
					opTable.pop_back();
					opTableType.pop_back();
				loop_label.pop_back();
			}
			| READ readVars
			| WRITE writeVars
			| CONTINUE {
				if(!loop_label.empty()) {
					string loopType = loop_label.back()[0];
					if (loopType == "while") {
						toPrint.push_back(":= " + loop_label.back()[1]);
					}
					else { //do_while loop
						toPrint.push_back(":= " + loop_label.back()[2]);
					}
				}
			}
			| RETURN expression {
				toPrint.push_back("ret " + opTable.back());
					opTable.pop_back();
					opTableType.pop_back();
			}
			;

assign:
			assignVar ASSIGN expression {
				string op2 = opTable.back();
				opTable.pop_back();
				opTableType.pop_back();

				string op1 = opTable.back();
				opTable.pop_back();
				string op1type = opTableType.back();
				opTableType.pop_back();
				if (op1type == "INT") {
					toPrint.push_back("= " + op1 + ", " + op2);
				}
				else {
					toPrint.push_back("[]= " + op1 + ", " + op2);
				}
			}
			;

assignVar: 
                        IDENT {
                                if (!idUsed($1)) {
                                        yyerror("variable is not defined.");
                                }
                                string temp = $1;
                                opTable.push_back(temp);
                                opTableType.push_back("INT");
                        }
                        | IDENT L_SQUARE_BRACKET expressions R_SQUARE_BRACKET {
                                if (!idUsed($1)) {
                                        yyerror("variable is not defined.");
                                }
                                string temp = $1;
                                string size = opTable.back();
                                        opTable.pop_back();
                                        opTableType.pop_back();
                                string id = temp + ", " + size;
                                opTable.push_back(id);
                                opTableType.push_back("ARRAY");
                        } 
                        ;

if_bool:
			IF bool_exp {
				vector<string> temp;
				temp.push_back("L" + to_string(labelCount++));
				temp.push_back("L" + to_string(labelCount++));
				temp.push_back("L" + to_string(labelCount++));
				if_label.push_back(temp);
				toPrint.push_back("?:= " + if_label.back()[0] + ", " + opTable.back()); 
					opTable.pop_back();
					opTableType.pop_back();
				toPrint.push_back(":= " + if_label.back()[1]);
				toPrint.push_back(": " + if_label.back()[0]);
			}
			;

if_else:
			ELSE statements {
				toPrint.push_back(":= " + if_label.back()[2]);
				toPrint.push_back(": " + if_label.back()[1]);
			}
			;

while_bool:
			while bool_exp BEGINLOOP {
				toPrint.push_back("?:= " + loop_label.back()[2] + ", " +opTable.back());
					opTable.pop_back();
					opTableType.pop_back();
				toPrint.push_back(":= " + loop_label.back()[3]);
				toPrint.push_back(": " + loop_label.back()[2]);
			}
			;

while:
			WHILE {
				vector<string> temp;
				temp.push_back("while");
				temp.push_back("L" + to_string(labelCount++));
				temp.push_back("L" + to_string(labelCount++));
				temp.push_back("L" + to_string(labelCount++));
				loop_label.push_back(temp);
				toPrint.push_back(": " + loop_label.back().at(1));
			}
			;

do_loop:
			do statements ENDLOOP {
				toPrint.push_back(": " + loop_label.back()[2]);
			}
			;

do:
			DO BEGINLOOP {
				vector<string> temp;
				temp.push_back("do_while");
				temp.push_back("L" + to_string(labelCount++));
				temp.push_back("L" + to_string(labelCount++));
				loop_label.push_back(temp);
				toPrint.push_back(": " + loop_label.back()[1]);
			}
			;

readVars:
			var {
				string op1 = opTable.back();
				string op1type = opTableType.back();
				opTable.pop_back();
				opTableType.pop_back();
				if (op1type == "INT") {
					toPrint.push_back(".< " + op1);
				}
				else {
					toPrint.push_back(".[]< " + op1);
				}
			}
			| var COMMA readVars { //same as above var
				string op1 = opTable.back();
				string op1type = opTableType.back();
				opTable.pop_back();
				opTableType.pop_back();
				if (op1type == "INT") {
					toPrint.push_back(".< " + op1);
				}
				else {
					toPrint.push_back(".[]< " + op1);
				}
			}
			;

writeVars: //same as above readVars
			var {
				string op1 = opTable.back();
				string op1type = opTableType.back();
				opTable.pop_back();
				opTableType.pop_back();
				if (op1type == "INT") {
					toPrint.push_back(".> " + op1);
				}
				else {
					toPrint.push_back(".[]> " + op1);
				}
			}
			| var COMMA readVars { //same as above var
				string op1 = opTable.back();
				string op1type = opTableType.back();
				opTable.pop_back();
				opTableType.pop_back();
				if (op1type == "INT") {
					toPrint.push_back(".> " + op1);
				}
				else {
					toPrint.push_back(".[]> " + op1);
				}
			}
			;

bool_exp:
			relation_and_exp 
			| relation_and_exp OR bool_exp {
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");

				string op2 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				string op1 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				toPrint.push_back("|| " + temp + ", " + op1 + ", " + op2);
				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			;
relation_and_exp:
			relation_exp 
			| relation_exp AND relation_and_exp {
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");

				string op2 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				string op1 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				
				toPrint.push_back("&& " + temp + ", " + op1 + ", " + op2);
				
				opTable.push_back(temp);
				opTableType.push_back("INT");
			} 
			;
relation_exp: 
			relation_exp1 
			| NOT relation_exp1 {
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");

				string op1 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				
				toPrint.push_back("! " + temp + ", " + op1);
				
				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			;
relation_exp1:
			expression comp expression {
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");

				string op2 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				string comp = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				string op1 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				
				toPrint.push_back(comp + " " + temp + ", " + op1 + ", " + op2);
				
				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			| TRUE {
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");
				
				toPrint.push_back("= " + temp + ", 1");
				
				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			| FALSE {
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");
				
				toPrint.push_back("= " + temp + ", 0");
				
				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			| L_PAREN bool_exp R_PAREN 
			;

comp:
			EQ {
				opTable.push_back("==");
				opTableType.push_back("null");
			}
			| NEQ {
				opTable.push_back("!=");
				opTableType.push_back("null");
			}
			| LT {
				opTable.push_back("<");
				opTableType.push_back("null");
			} 
			| GT {
				opTable.push_back(">");
				opTableType.push_back("null");
			}
			| LTE {
				opTable.push_back("<=");
				opTableType.push_back("null");
			}
			| GTE {
				opTable.push_back(">=");
				opTableType.push_back("null");
			}
			;

expressions:
			expression 
			| expression COMMA expression 
			;
			
expression:
			mult_expression 
			| mult_expression ADD expression { //same for SUB, MULT, DIV, MOD
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");
				string op2 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				string op1 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				
				toPrint.push_back("+ " + temp + ", " + op1 + ", " + op2);
				
				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			| mult_expression SUB expression {
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");
				string op2 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				string op1 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				
				toPrint.push_back("- " + temp + ", " + op1 + ", " + op2);
				
				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			;

mult_expression:	
			term
			| term MULT mult_expression {
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");
				string op2 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				string op1 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				
				toPrint.push_back("* " + temp + ", " + op1 + ", " + op2);
				
				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			| term DIV mult_expression {
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");
				string op2 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				string op1 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				
				toPrint.push_back("/ " + temp + ", " + op1 + ", " + op2);
				
				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			| term MOD mult_expression {
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");
				string op2 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				string op1 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				
				toPrint.push_back("% " + temp + ", " + op1 + ", " + op2);
				
				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			;

term:
			var 
			| NUMBER {
				opTable.push_back(to_string($1));
				opTableType.push_back("INT");
			}
			| SUB NUMBER {
				opTable.push_back(to_string($2*-1));
				opTableType.push_back("INT");
			}
			| L_PAREN expression R_PAREN 
			| SUB L_PAREN expression R_PAREN {
				string temp = "_t"+to_string(tempCount++);
				
				string op1 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				
				toPrint.push_back("- " + temp + ", 0, " + op1);
				
				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			| IDENT L_PAREN expressions R_PAREN { //call a function
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");

				string op1 = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();

				toPrint.push_back("param " + op1);
				toPrint.push_back(string("call ") + $1 + ", " + temp);

				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			;

var: 
			IDENT {
				if (!idUsed($1)) {
					yyerror("variable not defined.");
					findError = true;
				}
				string temp = $1;
				opTable.push_back(temp);
				opTableType.push_back("INT");
			}
			| IDENT L_SQUARE_BRACKET expressions R_SQUARE_BRACKET {
				if (!idUsed($1)) {
					yyerror("variable not defined.");
					findError = true;
				}
				string temp = "_t"+to_string(tempCount++);
					varTable.push_back(temp);
					varTableType.push_back("INT");

				string arraySize = opTable.back();
					opTable.pop_back();
					opTableType.pop_back();
				opTable.push_back(temp);
				opTableType.push_back("ARRAY");
				toPrint.push_back("=[] "+ temp + ", " + $1 + ", " + arraySize);
			} 
			;

%%


int main(int argc, char **argv) {
	if (argc > 1) {
		yyin = fopen(argv[1], "r");
		if (yyin == NULL) {
			printf("syntax: %s filename\n", argv[0]);
		}
	}
	yyparse();
	for(unsigned i = 0; i < functions.size(); i++) {
		if (functions[i] == "main") {
			findMain = true;
			break;
		}
	}

	if (!findMain) {
		printf("No main function defined!\n");
		return -1;
	}
	if (findError) {
		return -1;
	}

	for(unsigned i = 0; i < toPrintAll.size(); i++) {
		cout << toPrintAll[i] <<endl;
	}

	return 0;
}

void yyerror(const char *msg) {
	printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}


