%{
#include <stdio.h>
#include <string.h>
int yylex();
int lineCount = 1;
int cp = 1, nc = 0;
int if_cp;
int duplicate = 0;
int error_op = 0, error_expr=0;
char sstr[2048];
char no_comma[256];
char **symbol_table;
char dupli_str[256];
int *symbol_cp;
int symbol_index=0;
void ID_process(char*);
void yyerror(const char* message) {
    printf("Invaild format\n");
};
%}
%union {
    char stringVal[4096];
} 

%type <stringVal> ID DIGIT DECIMAL COMMENT STR
%type <stringVal> declaration array_declaration var_declaration datatype id_list assign const_expr op const_declaration const_id_list emptyline fields class code
%type <stringVal> create_object method method_arguments compound argument_list class_inside compound_statement simple expression term factor prefixop postfixop methodinvocation
%type <stringVal> method_passin condition boolean_expr condition_statement infixop loop forinitopt forupdateopt identifier for_argument_list return
%token ID INT NEWLINE FLOAT STATIC NEW DIGIT FINAL BOOLEAN CHAR STRING DECIMAL
%token CLASS MAIN WHILE PRINT VOID RETURN FOR IF ELSE COMMENT PLUSPLUS MINUSMINUS EQUALEQUAL NOTEQUAL GREATER SMALLER GE SE STR
%%

/*          印出結果            */
printline : code {
    printf("line%3d:", lineCount++);
    for(int i=0;i<strlen($1);i++){
        if(($1[i] == '\n') && ((i+1) < strlen($1)) && ($1[i+1] != '*')){
            printf("\nline%3d:", lineCount++);
        }
        else{
            printf("%c", $1[i]);
        }
        
    }
}

/*      整個檔案裡包含comment, class, newline       */

code :/*empty*/
    | code COMMENT NEWLINE{strcpy($$,$1);strcat($$," ");strcat($$,$2);strcat($$," \n");}
    | code class {strcpy($$,$1);strcat($$,$2);}
    | code NEWLINE {strcpy($$,$1);strcat($$," \n");}
    ;

/*      class       */

class : CLASS ID emptyline '{' class_inside '}' NEWLINE {strcpy($$," class ");strcat($$,$2);strcat($$,$3);strcat($$," {");strcat($$,$5);strcat($$," }");strcat($$,"\n");symbol_index=0;}
    ;

/*      class裡面可包含class, compound, fields, method, newline       */
class_inside:/*empty*/ {strcpy($$,"");}
    | class_inside class {strcpy($$,$1);strcat($$,$2);}
    | class_inside compound {strcpy($$,$1);strcat($$,$2);}
    | class_inside fields {strcpy($$,$1);strcat($$,$2);}
    | class_inside method {strcpy($$,$1);strcat($$,$2);}
    | class_inside NEWLINE {strcpy($$,$1);strcat($$," \n");}
    ;

/*      method宣告(必須有return type, 否則視為錯誤)      */
method : datatype ID '(' method_arguments ')' emptyline compound {strcpy($$,$1);strcat($$," ");strcat($$,$2);strcat($$," (");strcat($$,$4);strcat($$," )");strcat($$,$6);strcat($$,$7);}
    | datatype MAIN '(' method_arguments ')' emptyline compound {strcpy($$,$1);strcat($$," main (");strcat($$,$4);strcat($$," )");strcat($$,$6);strcat($$,$7);}
    | ID '(' method_arguments ')' NEWLINE compound {strcpy($$," ");strcat($$,$1);strcat($$," (");strcat($$,$3);strcat($$," )");strcat($$,"\n****** No return type for method declaration ******\n");strcat($$,$6);}
    | ID '(' method_arguments ')' compound {strcpy($$," ");strcat($$,$1);strcat($$," (");strcat($$,$3);strcat($$," ) {\n****** No return type for method declaration ******\n");strncpy(sstr,&$5[3],strlen($5)-3);sstr[strlen($5)-3] = '\0';strcat($$,sstr);}
    | MAIN '(' method_arguments ')' NEWLINE compound {strcpy($$," main (");strcat($$,$3);strcat($$," )");strcat($$,"\n****** No return type for main function ******\n");strcat($$,$6);}
    | MAIN '(' method_arguments ')' compound {strcpy($$," main (");strcat($$,$3);strcat($$," ) {\n****** No return type for main function ******\n");strncpy(sstr,&$5[3],strlen($5)-3);sstr[strlen($5)-3] = '\0';strcat($$,sstr);}
    ;

compound : '{' compound_statement '}' NEWLINE {strcpy($$," {");strcat($$,$2);strcat($$," }\n");}
    ;

/*compound statement  包含condition, loop, ....*/
compound_statement: /*empty*/ {strcpy($$,"");}
    | compound_statement compound {strcpy($$,$1);strcat($$,$2);}
    | compound_statement return {strcpy($$,$1);strcat($$,$2);}
    | compound_statement loop {strcpy($$,$1);strcat($$,$2);}
    | compound_statement condition {strcpy($$,$1);strcat($$,$2);}
    | compound_statement simple {strcpy($$,$1);strcat($$,$2);}
    | compound_statement NEWLINE {strcpy($$,$1);strcat($$," \n");}
    | compound_statement class {strcpy($$,$1);strcat($$,$2);}
    ;

/*          return        */
return : RETURN expression ';' {strcpy($$," return");strcat($$,$2);strcat($$," ;");}
    ;

/*        loop(while / for)            */
loop : WHILE '(' boolean_expr ')' emptyline compound {if(error_op){strcpy($$,"****** invalid boolean expression at next line ******\n");error_op=0;strcat($$," while (");}else{strcpy($$," while (");}strcat($$,$3);strcat($$," )");strcat($$,$5);strcat($$,$6);}
    | WHILE '(' boolean_expr ')' emptyline simple {if(error_op){strcpy($$,"****** invalid boolean expression at next line ******\n");error_op=0;strcat($$," while (");}else{strcpy($$," while (");}strcat($$,$3);strcat($$," )");strcat($$,$5);strcat($$,$6);}
    | FOR '(' forinitopt ';' boolean_expr ';' forupdateopt ')' emptyline compound {if(error_op){strcpy($$,"****** invalid boolean expression at next line ******\n");error_op=0;strcat($$," for (");}else{strcpy($$," for (");}strcat($$,$3);strcat($$," ;");strcat($$,$5);strcat($$," ;");strcat($$,$7);strcat($$," )");strcat($$,$9);strcat($$,$10);}
    | FOR '(' forinitopt ';' boolean_expr ';' forupdateopt ')' emptyline simple {if(error_op){strcpy($$,"****** invalid boolean expression at next line ******\n");error_op=0;strcat($$," for (");}else{strcpy($$," for (");}strcat($$,$3);strcat($$," ;");strcat($$,$5);strcat($$," ;");strcat($$,$7);strcat($$," )");strcat($$,$9);strcat($$,$10);}
    ;
    
/*      for loop(可以在這裡宣告變數,或是使用先前宣告的變數)        */
forinitopt : INT identifier '=' expression for_argument_list {strcpy($$," int");strcat($$,$2);strcat($$," =");strcat($$,$4);strcat($$,$5);}
    | identifier '=' expression for_argument_list {strcpy($$,$1);strcat($$," =");strcat($$,$3);strcat($$,$4);}
    ;
/*      更新變數(++ / --)    */
forupdateopt : identifier PLUSPLUS {strcpy($$,$1);strcat($$," ++");}
    | identifier MINUSMINUS  {strcpy($$,$1);strcat($$," --");}

for_argument_list :/*empty*/ {strcpy($$,"");}
    | for_argument_list ',' identifier '=' expression {strcpy($$,$1);strcat($$," ,");strcat($$,$3);strcat($$," =");strcat($$,$5);}
    ;

/*        condition(可以有else,也可以沒有,但else一定要在if後面出現)      */
condition : IF '(' boolean_expr ')' condition_statement {strcpy($$," if (");strcat($$,$3);strcat($$," )");strcat($$,$5);}
    | ELSE NEWLINE condition_statement {strcpy($$," else \n");if(if_cp != cp){strcat($$,"****** else without if statement. ******\n");}strcat($$,$3);}
    ;

boolean_expr : expression infixop expression {strcpy($$,$1);strcat($$,$2);strcat($$,$3);}
    | expression {strcpy($$,$1);}
    | op op op expression {strcpy($$,$1);strcat($$,$2);strcat($$,$3);strcat($$,$4);error_op=1;}
    ;
/*      condition中的比較       */
infixop : EQUALEQUAL {strcpy($$," ==");}
    | NOTEQUAL {strcpy($$," !=");}
    | GREATER {strcpy($$," >");}
    | SMALLER {strcpy($$," <");}
    | GE {strcpy($$," >=");}
    | SE {strcpy($$," <=");}
    ;

condition_statement : simple {strcpy($$,$1);}
    | compound {strcpy($$,$1);}
    ;

/*          simple(賦予變數數值, print, id++/--)       */
simple : fields {strcpy($$,$1);}
    | identifier '=' expression ';' NEWLINE {strcpy($$,$1);strcat($$," =");strcat($$,$3);strcat($$," ;\n");if(error_expr){strcat($$,"****** error expression ******\n");error_expr=0;}}
    | PRINT '(' expression ')' ';' NEWLINE {strcpy($$," print (");strcat($$,$3);strcat($$," ) ;\n");if(error_expr){strcat($$,"****** error expression ******\n");error_expr=0;}}
    | identifier PLUSPLUS ';' NEWLINE {strcpy($$,$1);strcat($$," ++ ;\n");}
    | identifier MINUSMINUS ';' NEWLINE {strcpy($$,$1);strcat($$," -- ;\n");}
    ;

expression: term {strcpy($$,$1);}
    | expression '+' term {strcpy($$,$1);strcat($$," +");strcat($$,$3);}
    | expression '-' term {strcpy($$,$1);strcat($$," -");strcat($$,$3);}
    ;

term : factor {strcpy($$,$1);}
    | term '*' factor {strcpy($$,$1);strcat($$," *");strcat($$,$3);}
    | term '/' factor {strcpy($$,$1);strcat($$," /");strcat($$,$3);}
    ;

factor : DIGIT {strcpy($$," ");strcat($$,$1);} 
    | STR {strcpy($$," ");strcat($$,$1);}
    | identifier {strcpy($$,$1);}
    | '(' expression ')' {strcpy($$," (");strcat($$,$2);strcat($$," )");}
    | prefixop identifier {strcpy($$,$1);strcat($$,$2);}
    | prefixop DIGIT {strcpy($$,$1);strcat($$,$2);error_expr=1;}
    | identifier postfixop {strcpy($$,$1);strcat($$,$2);}
    | DIGIT postfixop {strcpy($$,$1);strcat($$,$2);error_expr=1;}
    | methodinvocation {strcpy($$,$1);}
    ;

prefixop : PLUSPLUS {strcpy($$," ++");}
    | MINUSMINUS {strcpy($$," --");}
    | '+' {strcpy($$," +");}
    | '-' {strcpy($$," -");}
    ;

postfixop : PLUSPLUS {strcpy($$," ++");}
    | MINUSMINUS {strcpy($$," --");}
    ;

/*      呼叫method    */
methodinvocation : ID '(' method_passin ')' {strcpy($$," ");strcat($$,$1);strcat($$," (");strcat($$,$3);strcat($$," )");}
    ;

/*      傳入method的參數        */    
method_passin : /*empty*/ {strcpy($$,"");}
    | expression {strcpy($$,$1);}
    | method_passin ',' expression {strcpy($$,$1);strcat($$," ,");strcat($$,$3);}
    ;


/*  宣告method的參數  */
method_arguments :/*empty*/ {strcpy($$,"");}
    | argument_list {strcpy($$,$1);}
    ;

argument_list : datatype identifier {strcpy($$,$1);strcat($$,$2);}
    | argument_list ',' datatype identifier {strcpy($$,$1);strcat($$," ,");strcat($$,$3);strcat($$,$4);}
    ;

emptyline:/*empty*/ {strcpy($$,"");}
    | NEWLINE {strcpy($$," \n");}
    ;



/*        Data Types and Declarations        */
/*      宣告, 註解, 或創建新的物件(結尾沒有';'會報錯)      */
fields : declaration ';' NEWLINE {strcpy($$,$1);strcat($$," ;\n"); if(duplicate){strcat($$,"****** '");strcat($$,dupli_str);strcat($$,"' is a duplicate identifier. ******\n");duplicate=0;}if(nc){strcat($$,"****** need ',' before");strcat($$,no_comma);strcat($$," ******\n");nc=0;}}
    | declaration NEWLINE {strcpy($$,$1);strcat($$,"\n");strcat($$,"****** statement without semicolon at EOL. ******\n");if(duplicate){strcat($$,"****** '");strcat($$,dupli_str);strcat($$,"' is a duplicate odentifier. ******\n");duplicate=0;}}
    | COMMENT NEWLINE {strcpy($$," ");strcat($$,$1);strcat($$,"\n");}
    | create_object ';' NEWLINE {strcpy($$,$1);strcat($$," ;\n");if(duplicate){strcat($$,"****** '");strcat($$,dupli_str);strcat($$,"' is a duplicate identifier. ******\n");duplicate=0;}}
    | create_object NEWLINE {strcpy($$,$1);strcat($$,"\n");strcat($$,"****** statement without semicolon at EOL. ******\n");}
    ;

/*      創建一個新的object      */
create_object : ID ID '=' NEW ID '(' ')' {strcpy($$," ");strcat($$,$1);strcat($$," ");strcat($$,$2);ID_process($2);strcat($$," =");strcat($$," new ");strcat($$,$5);strcat($$," ( )");}
    ;
/*    三種宣告      */
declaration : var_declaration {strcpy($$,$1);}
    | array_declaration {strcpy($$,$1);}
    | const_declaration {strcpy($$,$1);}
    ;

/*  常數宣告   final  */
const_declaration : FINAL datatype const_id_list {strcpy($$," final");strcat($$,$2);strcat($$,$3);}
    ;

const_id_list : ID '=' const_expr {ID_process($1);strcpy($$," ");strcat($$,$1);strcat($$," =");strcat($$,$3);}
    | const_id_list ',' ID '=' const_expr {strcpy($$,$1);strcat($$," , ");strcat($$,$3);ID_process($3);strcat($$," =");strcat($$,$5);}
    ;

/* array 宣告 */
array_declaration : datatype '[' ']' ID '=' NEW datatype '[' DIGIT ']' {strcpy($$,$1);strcat($$," [");strcat($$," ] ");strcat($$,$4);ID_process($4);strcat($$," =");strcat($$," new");strcat($$,$7);strcat($$," [ ");strcat($$,$9);strcat($$," ]");}
    ;

/*      變數宣告        */
var_declaration : datatype id_list {strcpy($$,$1);strcat($$,$2);}
    | STATIC datatype id_list {strcpy($$," static");strcat($$,$2);strcat($$,$3);}
    ;

/*    int a (,b,c....);  */
id_list : assign {strcpy($$,$1);}
    | id_list ',' assign {strcpy($$,$1);strcat($$," ,");strcat($$,$3);}
    | id_list assign {strcpy($$,$1);strcat($$," ");strcat($$,$2);strcpy(no_comma,$2);nc=1;}
    ;

/* 初始值可有可無  */
assign : identifier {strcpy($$,$1);ID_process($1);}
    | identifier '=' const_expr {strcpy($$,$1);ID_process($1);strcat($$," =");strcat($$,$3);}
    ;

/* 變數賦予初始值 */
const_expr : DIGIT {strcpy($$," ");strcat($$,$1);}
    | const_expr op DIGIT {strcpy($$,$1);strcat($$,$2);strcat($$," ");strcat($$,$3);}
    | DECIMAL {strcpy($$," ");strcat($$,$1);}
    | const_expr op DECIMAL {strcpy($$,$1);strcat($$,$2);strcat($$," ");strcat($$,$3);}
    | ID {strcpy($$," ");strcat($$,$1);}
    | const_expr op ID {strcpy($$,$1);strcat($$,$2);strcat($$," ");strcat($$,$3);}
    ;

/*      運算符號        */
op : '+' {strcpy($$," +");}
    | '-' {strcpy($$," -");}
    | '*' {strcpy($$," *");}
    | '/' {strcpy($$," /");}
    ;

/*      變數型態        */
datatype : INT {strcpy($$," int");}
    | FLOAT {strcpy($$," float");}
    | BOOLEAN {strcpy($$," boolean");}
    | CHAR {strcpy($$," char");}
    | STRING {strcpy($$," String");}
    | VOID {strcpy($$," void");}
    ;

/*  兩種id ( ex: i  /  i[1] )    */
identifier : ID {strcpy($$," ");strcat($$,$1);}
    | ID '[' DIGIT ']' {strcpy($$," ");strcat($$,$1);strcat($$," [ ");strcat($$,$3);strcat($$," ]");}
    ;

%%
/*  創建一個symbol table    */
void create(){
	symbol_table=(char **)malloc(10000*sizeof(char *));
    symbol_cp=(int *)malloc(10000*sizeof(int));
    for(int i=0;i<10000;i++){
        symbol_table[i]=(char*)malloc(100*sizeof(char));
    }
	symbol_index = 0;
}

/*  處理ID,檢查是否重複宣告,並加入symbol table中    */
void ID_process(char* str){
    if(str[0] == ' '){
        for(int i=0;i<strlen(str)-1;i++){
            str[i] = str[i+1];
        }
        str[strlen(str)-1] = '\0';
    }
    for(int i=0;i<symbol_index;i++){
		if((strcmp(symbol_table[i],str) == 0) && (cp == symbol_cp[i])){
			duplicate = 1;
            strcpy(dupli_str, str);
            break;
		}
	}
    if(!duplicate){
        strcpy(symbol_table[symbol_index],str);
        symbol_cp[symbol_index] = cp;
        symbol_index++;
    }
}
int main() {
    create();
    yyparse();
    return 0;
}
