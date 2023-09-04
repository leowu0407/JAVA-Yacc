%{
#include "y.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern int lineCount;
extern int cp;
extern int duplicate;
int idx;
extern int if_cp;
extern int error_expr;
char cmt[1024];
%}
space [ \t]
eol [\n]
comment \/\*([^\*]|\*[^\/])*\*\/|\/\/[^\r\n]*
id [a-zA-Z][0-9a-zA-Z]*
digit [0-9]+
decimal ([0-9]+(\.[0-9]*)?|\.[0-9]+)([Ee][+-]?[0-9]+)?[Ff]?
symbol [\;\,\[\]\=\+\-\*\/\(\)]
str \"([^\\\"\n]|\\\\|\\\"|\\\'|\\n|\\t|\\r|\\0|\\b|\\f)*\"
%%
"{"	{
	/*進入新的compound*/
	cp++;
	return yytext[0];
}
"}"	{
	/*離開compound*/
	cp--;
	return yytext[0];
}
{space}	{
	;
}
{str}	{
	strcpy(yylval.stringVal, yytext);
	return STR;
}
{eol}   {
	return NEWLINE;
}
"++"	{
	return PLUSPLUS;
}
"--"	{
	return MINUSMINUS;
}
"=="	{
	return EQUALEQUAL;
}
"!="	{
	return NOTEQUAL;
}
">"	{
	return GREATER;
}
"<"	{
	return SMALLER;
}
">="	{
	return GE;
}
"<="	{
	return SE;
}
class	{
	return CLASS;
}
final	{
	return FINAL;
}
int		{
	return INT;
}
main	{
	return MAIN;
}
while	{
	return WHILE;
}
print	{
	return PRINT;
}
static	{
	return STATIC;
}
void	{
	return VOID;
}
float	{
	return FLOAT;
}
new {
	return NEW;
}
boolean	{
	return BOOLEAN;
}
char	{
	return CHAR;
}
return	{
	return RETURN;
}
for	{
	return FOR;
}
if	{
	if_cp = cp;
	return IF;
}
else	{
	return ELSE;
}
String	{
	return STRING;
}
{comment} {
	if(yytext[1] == '*'){
		idx = 0;
		strcpy(cmt,"");
		for(int i=0;i<strlen(yytext);i++){
			cmt[idx++] = yytext[i];
			if(yytext[i] == '\n'){
				cmt[idx++] = ' ';
			}
		}
		cmt[idx] = '\0';
		strcpy(yylval.stringVal, cmt);
	}
	else{
		strcpy(yylval.stringVal, yytext);
	}
	return COMMENT;
}
{id}	{
	strcpy(yylval.stringVal, yytext);
	return ID;
}
{digit}	{
	strcpy(yylval.stringVal, yytext);
	return DIGIT;
}
{decimal}	{
	strcpy(yylval.stringVal, yytext);
	return DECIMAL;
}
{symbol}	{
	return yytext[0];
}
%%
int yywrap(){
	return 1;
 }
