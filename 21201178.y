%{
#include "symbol_info.h"
#include "symbol_table.h"
#define YYSTYPE symbol_info*

int yyparse(void);
int yylex(void);
void yyerror(const char *s);
extern FILE *yyin;

symbol_table* st;
ofstream outlog;
int lines = 1;
string current_type = "int"; 



void yyerror(const char *s) {
    outlog << "Error at line " << lines << ": " << s << endl;
}

// Global variables for function handling
std::vector<std::pair<std::string,std::string> > current_function_params;
std::string current_function_name;
std::string current_function_return_type;

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
    {
        outlog << "At line no: " << lines << " start : program" << endl << endl;
    }
    ;

program : program unit
    {
        outlog << "At line no: " << lines << " program : program unit" << endl << endl;
        outlog << $1->getname() << "\n" << $2->getname() << endl << endl;
        $$ = new symbol_info($1->getname() + "\n" + $2->getname(), "program");
    }
    | unit
    {
        outlog << "At line no: " << lines << " program : unit" << endl << endl;
        outlog << $1->getname() << endl << endl;
        $$ = new symbol_info($1->getname(), "program");
    }
    ;

unit : var_declaration
    {
        outlog << "At line no: " << lines << " unit : var_declaration" << endl << endl;
        outlog << $1->getname() << endl << endl;
        $$ = $1;
    }
    | func_definition
    {
        outlog << "At line no: " << lines << " unit : func_definition" << endl << endl;
        outlog << $1->getname() << endl << endl;
     
        $$ = $1;
    }
    ;

func_definition
    : type_specifier ID LPAREN parameter_list RPAREN 
    {
        current_function_name = $2->getname();
        current_function_return_type = $1->getname();
        
        symbol_info* func_symbol = new symbol_info(current_function_name, "ID", "function", current_function_return_type);
        
        // Build parameter list  (vector<string>)
        std::vector<std::string> param_list;
        for (size_t i = 0; i < current_function_params.size(); i++) {
            param_list.push_back(current_function_params[i].second + " " + current_function_params[i].first);
        }
        func_symbol->set_parameters(param_list);
        
        if (!st->insert(func_symbol)) {
            outlog << "Error: Function " << current_function_name << " already declared" << endl;
        }
    } 
    compound_statement
    {
        // Build the display string 
        std::string param_str;
        for (size_t i = 0; i < current_function_params.size(); i++) {
            if (i != 0) param_str += ", ";
            param_str += current_function_params[i].second + " " + current_function_params[i].first;
        }
        
        $$ = new symbol_info($1->getname() + " " + $2->getname() + "(" + param_str + ")\n" + $7->getname(), "func_def");
        current_function_params.clear();
    }
    | type_specifier ID LPAREN RPAREN 
    {
        current_function_name = $2->getname();
        current_function_return_type = $1->getname();
        current_function_params.clear();
        
        // Insert function into global scope
        symbol_info* func_symbol = new symbol_info(current_function_name, "ID", "function", current_function_return_type);
        
        if (!st->insert(func_symbol)) {
            outlog << "Error: Function " << current_function_name << " already declared" << endl;
        }
        
    } compound_statement
    {
        $$ = new symbol_info($1->getname() + " " + $2->getname() + "()\n" + $6->getname(), "func_def");
    };


parameter_list
    : parameter_list COMMA type_specifier ID
    {
        outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier ID" << endl << endl;
        outlog << $1->getname() << "," << $3->getname() << " " << $4->getname() << endl << endl;
     

        // Add parameter to the current function's parameter list
        current_function_params.push_back({$4->getname(), $3->getname()});
        
        $$ = new symbol_info($1->getname() + "," + $3->getname() + " " + $4->getname(), "param_list");
    }
    | parameter_list COMMA type_specifier
    {
        outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier" << endl << endl;
        outlog << $1->getname() << "," << $3->getname() << endl << endl;
        $$ = new symbol_info($1->getname() + "," + $3->getname(), "param_list");
    }
    | type_specifier ID
    {
        outlog << "At line no: " << lines << " parameter_list : type_specifier ID" << endl << endl;
        outlog << $1->getname() << " " << $2->getname() << endl << endl;


        // Initialize and add first parameter
        current_function_params.clear();
        current_function_params.push_back({$2->getname(), $1->getname()});
        
        $$ = new symbol_info($1->getname() + " " + $2->getname(), "param_list");
    }
    | type_specifier
    {
        outlog << "At line no: " << lines << " parameter_list : type_specifier" << endl << endl;
        outlog << $1->getname() << endl << endl;
        current_function_params.clear(); // No named parameters
        $$ = new symbol_info($1->getname(), "param_list");
    }
    ;

compound_statement : LCURL 
    {
        st->enter_scope();
        
        for (size_t i = 0; i < current_function_params.size(); i++) {
            std::string full_name = current_function_params[i].second + " " + current_function_params[i].first;
            symbol_info* param_symbol = new symbol_info(
                full_name,  
                "ID", 
                "variable", 
                current_function_params[i].second
            );
            if (!st->insert(param_symbol)) {
                outlog << "Error: Parameter " << current_function_params[i].first << " already declared" << endl;
            }
        }
    } 
   
    statements RCURL
    {   
        outlog << "At line no: " << lines << " compound_statement : LCURL statements RCURL" << endl << endl;
        outlog << "{\n" << $3->getname() << "\n}" << endl << endl;

        // Print symbol table before exiting scope
        outlog << "################################" << endl << endl;
        st->print_all_scopes(outlog);
        outlog << "################################" << endl << endl;

        st->exit_scope();

        $$ = new symbol_info("{\n" + $3->getname() + "\n}", "compound_stmt");
    }
    | LCURL RCURL
    {
        outlog << "At line no: " << lines << " compound_statement : LCURL RCURL" << endl << endl;
        outlog << "{\n}" << endl << endl;
        
        // Even for empty compound statements, we should enter and exit scope
        st->enter_scope();
        
        // Insert function parameters if any
        for (size_t i = 0; i < current_function_params.size(); i++) {
            symbol_info* param_symbol = new symbol_info(
                current_function_params[i].first, 
                "ID", 
                "variable", 
                current_function_params[i].second
            );
            st->insert(param_symbol);
        }
        
        outlog << "################################" << endl << endl;
        st->print_current_scope(outlog);
        outlog << "################################" << endl << endl;
        
        st->exit_scope();
        
        $$ = new symbol_info("{\n}", "compound_stmt");
    }

var_declaration : type_specifier declaration_list SEMICOLON
{
    // Don't set current_type here - it's too late!
    outlog << "At line no: " << lines << " var_declaration : type_specifier declaration_list SEMICOLON" << endl << endl;
    outlog << $1->getname() << " " << $2->getname() << ";" << endl << endl;
    $$ = new symbol_info($1->getname() + " " + $2->getname() + ";", "var_decl");
}
;

type_specifier : INT
    {
        current_type = "int";  // Set current_type here
        outlog << "At line no: " << lines << " type_specifier : INT" << endl << endl;
        outlog << "int" << endl << endl;
        $$ = new symbol_info("int", "type");
    }
    | FLOAT
    {
        current_type = "float";  // Set current_type here
        outlog << "At line no: " << lines << " type_specifier : FLOAT" << endl << endl;
        outlog << "float" << endl << endl;
        $$ = new symbol_info("float", "type");
    }
    | VOID
    {
        current_type = "void";  // Set current_type here
        outlog << "At line no: " << lines << " type_specifier : VOID" << endl << endl;
        outlog << "void" << endl << endl;
        $$ = new symbol_info("void", "type");
    }
    ;

declaration_list : declaration_list COMMA ID
{
    
    outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID" << endl << endl;
    outlog << $1->getname() << "," << $3->getname() << endl << endl;

    // Use current_type explicitly here
    symbol_info* var_symbol = new symbol_info($3->getname(), "ID", "variable", current_type);
    if (!st->insert(var_symbol)) {
        outlog << "Error: Variable " << $3->getname() << " already declared in this scope" << endl;
    }

    $$ = new symbol_info($1->getname() + "," + $3->getname(), "decl_list");
}
| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
{
    outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" << endl << endl;
    outlog << $1->getname() << "," << $3->getname() << "[" << $5->getname() << "]" << endl << endl;

    symbol_info* array_symbol = new symbol_info($3->getname(), "ID", "array", current_type);
    array_symbol->set_array_size(atoi($5->getname().c_str()));
    if (!st->insert(array_symbol)) {
        outlog << "Error: Array " << $3->getname() << " already declared in this scope" << endl;
    }

    $$ = new symbol_info($1->getname() + "," + $3->getname() + "[" + $5->getname() + "]", "decl_list");
}
| ID
{

    outlog << "At line no: " << lines << " declaration_list : ID" << endl << endl;
    outlog << $1->getname() << endl << endl;

    symbol_info* var_symbol = new symbol_info($1->getname(), "ID", "variable", current_type);
    if (!st->insert(var_symbol)) {
        outlog << "Error: Variable " << $1->getname() << " already declared in this scope" << endl;
    }

    $$ = $1;
}
| ID LTHIRD CONST_INT RTHIRD
{
    outlog << "At line no: " << lines << " declaration_list : ID LTHIRD CONST_INT RTHIRD" << endl << endl;
    outlog << $1->getname() << "[" << $3->getname() << "]" << endl << endl;

    symbol_info* array_symbol = new symbol_info($1->getname(), "ID", "array", current_type);
    array_symbol->set_array_size(atoi($3->getname().c_str()));
    if (!st->insert(array_symbol)) {
        outlog << "Error: Array " << $1->getname() << " already declared in this scope" << endl;
    }

    $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "decl_list");
}
;



statements : statement
    {
        outlog << "At line no: " << lines << " statements : statement" << endl << endl;
        outlog << $1->getname() << endl << endl;
        $$ = $1;
    }
    |statements statement
    {
        outlog << "At line no: " << lines << " statements : statements statement" << endl << endl;
        outlog << $1->getname() << "\n" << $2->getname() << endl << endl;
        $$ = new symbol_info($1->getname() + "\n" + $2->getname(), "statements");
    }
    ;

statement : var_declaration
    {
        outlog << "At line no: " << lines << " statement : var_declaration" << endl << endl;
        outlog << $1->getname() << endl << endl;
     
        $$ = new symbol_info($1->getname(), "statement");
    }
    | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->getname()<<endl<<endl;
            $$ = new symbol_info($1->getname(),"stmnt");
	  }
    | expression_statement
    {
        outlog << "At line no: " << lines << " statement : expression_statement" << endl << endl;
        outlog << $1->getname() << endl << endl;
        
        $$ = new symbol_info($1->getname(), "statement");
    }
    | compound_statement
    {
        outlog << "At line no: " << lines << " statement : compound_statement" << endl << endl;
        outlog << $1->getname() << endl << endl;
    
        $$ = new symbol_info($1->getname(), "statement");
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    {
        outlog << "At line no: " << lines << " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement" << endl << endl;
        outlog << "for(" << $3->getname() << $4->getname() << $5->getname() << ")\n" << $7->getname() << endl << endl;
     
        $$ = new symbol_info("for(" + $3->getname() + $4->getname() + $5->getname() + ")\n" + $7->getname(), "statement");
    }
    | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
    {
        outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement" << endl << endl;
        outlog << "if(" << $3->getname() << ")\n" << $5->getname() << endl << endl;
    
        $$ = new symbol_info("if(" + $3->getname() + ")\n" + $5->getname(), "statement");
    }
    | IF LPAREN expression RPAREN statement ELSE statement
    {
        outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement ELSE statement" << endl << endl;
        outlog << "if(" << $3->getname() << ")\n" << $5->getname() << "\nelse\n" << $7->getname() << endl << endl;
       
        $$ = new symbol_info("if(" + $3->getname() + ")\n" + $5->getname() + "\nelse\n" + $7->getname(), "statement");
    }
    | WHILE LPAREN expression RPAREN statement
    {
        outlog << "At line no: " << lines << " statement : WHILE LPAREN expression RPAREN statement" << endl << endl;
        outlog << "while(" << $3->getname() << ")\n" << $5->getname() << endl << endl;
      
        $$ = new symbol_info("while(" + $3->getname() + ")\n" + $5->getname(), "statement");
    }
    | PRINTLN LPAREN ID RPAREN SEMICOLON
    {
        outlog << "At line no: " << lines << " statement : PRINTLN LPAREN ID RPAREN SEMICOLON" << endl << endl;
        outlog << "printf(" << $3->getname() << ");" << endl << endl;
     
        $$ = new symbol_info("printf(" + $3->getname() + ");", "statement");
    }
    
    | RETURN expression SEMICOLON
    {
        outlog << "At line no: " << lines << " statement : RETURN expression SEMICOLON" << endl << endl;
        outlog << "return " << $2->getname() << ";" << endl << endl;
   
        $$ = new symbol_info("return " + $2->getname() + ";", "statement");
    }
    ;

expression_statement : SEMICOLON
    {
        outlog << "At line no: " << lines << " expression_statement : SEMICOLON" << endl << endl;
        outlog << ";" << endl << endl;
        $$ = new symbol_info(";", "expr_stmt");
    }
    | expression SEMICOLON
    {
        outlog << "At line no: " << lines << " expression_statement : expression SEMICOLON" << endl << endl;
        outlog << $1->getname() << ";" << endl << endl;
        $$ = new symbol_info($1->getname() + ";", "expr_stmt");
    }
    ;

variable : ID
    {
        outlog << "At line no: " << lines << " variable : ID" << endl << endl;
        outlog << $1->getname() << endl << endl;
        $$ = $1;
    }
    | ID LTHIRD expression RTHIRD
    {
        outlog << "At line no: " << lines << " variable : ID LTHIRD expression RTHIRD" << endl << endl;
        outlog << $1->getname() << "[" << $3->getname() << "]" << endl << endl;
        $$ = new symbol_info($1->getname() + "[" + $3->getname() + "]", "variable");
    }
    ;

expression : logic_expression
    {
        outlog << "At line no: " << lines << " expression : logic_expression" << endl << endl;
        outlog << $1->getname() << endl << endl;
       
        $$ = $1;
    }
    | variable ASSIGNOP logic_expression
    {
        outlog << "At line no: " << lines << " expression : variable ASSIGNOP logic_expression" << endl << endl;
        outlog << $1->getname() << "=" << $3->getname() << endl << endl;
   
        $$ = new symbol_info($1->getname() + "=" + $3->getname(), "expression");
    }
    ;

logic_expression : rel_expression
    {
        outlog << "At line no: " << lines << " logic_expression : rel_expression" << endl << endl;
        outlog << $1->getname() << endl << endl;
   
        $$ = $1;
    }
    | rel_expression LOGICOP rel_expression
    {
        outlog << "At line no: " << lines << " logic_expression : rel_expression LOGICOP rel_expression" << endl << endl;
        outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
      
        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "logic_expression");
    }
    ;

rel_expression : simple_expression
    {
        outlog << "At line no: " << lines << " rel_expression : simple_expression" << endl << endl;
        outlog << $1->getname() << endl << endl;
 
        $$ = $1;
    }
    | simple_expression RELOP simple_expression
    {
        outlog << "At line no: " << lines << " rel_expression : simple_expression RELOP simple_expression" << endl << endl;
        outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;
  
        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "rel_expression");
    }
    ;

simple_expression : term
    {
        outlog << "At line no: " << lines << " simple_expression : term" << endl << endl;
        outlog << $1->getname() << endl << endl;

        $$ = $1;
    }
    | simple_expression ADDOP term
    {
        outlog << "At line no: " << lines << " simple_expression : simple_expression ADDOP term" << endl << endl;
        outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;

        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "simple_expression");
    }
    ;

term : unary_expression
    {
        outlog << "At line no: " << lines << " term : unary_expression" << endl << endl;
        outlog << $1->getname() << endl << endl;

        $$ = $1;
    }
    | term MULOP unary_expression
    {
        outlog << "At line no: " << lines << " term : term MULOP unary_expression" << endl << endl;
        outlog << $1->getname() << $2->getname() << $3->getname() << endl << endl;

        $$ = new symbol_info($1->getname() + $2->getname() + $3->getname(), "term");
    }
    ;

unary_expression : ADDOP unary_expression
    {
        outlog << "At line no: " << lines << " unary_expression : ADDOP unary_expression" << endl << endl;
        outlog << $1->getname() << $2->getname() << endl << endl;

        $$ = new symbol_info($1->getname() + $2->getname(), "unary_expression");
    }
    | NOT unary_expression
    {
        outlog << "At line no: " << lines << " unary_expression : NOT unary_expression" << endl << endl;
        outlog << "!" << $2->getname() << endl << endl;

        $$ = new symbol_info("!" + $2->getname(), "unary_expression");
    }
    | factor
    {
        outlog << "At line no: " << lines << " unary_expression : factor" << endl << endl;
        outlog << $1->getname() << endl << endl;

        $$ = $1;
    }
    ;

factor : variable
    {
        outlog << "At line no: " << lines << " factor : variable" << endl << endl;
        outlog << $1->getname() << endl << endl;

        $$ = $1;
    }
    | ID LPAREN argument_list RPAREN
    {
        outlog << "At line no: " << lines << " factor : ID LPAREN argument_list RPAREN" << endl << endl;
        outlog << $1->getname() << "(" << $3->getname() << ")" << endl << endl;

        $$ = new symbol_info($1->getname() + "(" + $3->getname() + ")", "factor");
    }
    | LPAREN expression RPAREN
    {
        outlog << "At line no: " << lines << " factor : LPAREN expression RPAREN" << endl << endl;
        outlog << "(" << $2->getname() << ")" << endl << endl;

        $$ = new symbol_info("(" + $2->getname() + ")", "factor");
    }
    | CONST_INT
    {
        outlog << "At line no: " << lines << " factor : CONST_INT" << endl << endl;
        outlog << $1->getname() << endl << endl;

        $$ = $1;
    }
    | CONST_FLOAT
    {
        outlog << "At line no: " << lines << " factor : CONST_FLOAT" << endl << endl;
        outlog << $1->getname() << endl << endl;

        $$ = $1;
    }
    | variable INCOP
    {
        outlog << "At line no: " << lines << " factor : variable INCOP" << endl << endl;
        outlog << $1->getname() << "++" << endl << endl;

        $$ = new symbol_info($1->getname() + "++", "factor");
    }
    | variable DECOP
    {
        outlog << "At line no: " << lines << " factor : variable DECOP" << endl << endl;
        outlog << $1->getname() << "--" << endl << endl;

        $$ = new symbol_info($1->getname() + "--", "factor");
    }
    ;

argument_list : arguments
    {
        outlog << "At line no: " << lines << " argument_list : arguments" << endl << endl;
        outlog << $1->getname() << endl << endl;
        $$ = $1;
    }
    | /* empty */
    {
        outlog << "At line no: " << lines << " argument_list : " << endl << endl;
        outlog << "" << endl << endl;
        $$ = new symbol_info("", "argument_list");
    }
    ;

arguments : arguments COMMA logic_expression
    {
        outlog << "At line no: " << lines << " arguments : arguments COMMA logic_expression" << endl << endl;
        outlog << $1->getname() << "," << $3->getname() << endl << endl;
        $$ = new symbol_info($1->getname() + "," + $3->getname(), "arguments");
    }
    | logic_expression
    {
        outlog << "At line no: " << lines << " arguments : logic_expression" << endl << endl;
        outlog << $1->getname() << endl << endl;
        $$ = $1;
    }
    ;

%%

int main(int argc, char *argv[]) {
    if(argc != 2) {
        cout << "Usage: ./a.out <input_file>" << endl;
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if(yyin == NULL) {
        cerr << "Couldn't open input file" << endl;
        return 1;
    }

    outlog.open("21201178_log.txt", ios::trunc);
    if (!outlog.is_open()) {
        cerr << "Failed to open 21201178_log.txt" << endl;
        return 1;
    }

    // Initialize symbol table
    st = new symbol_table(7); 

    yyparse();

    // Print final symbol table
    outlog << "\n===== Final Symbol Table =====\n";
    outlog << "################################" << endl << endl;
    st->print_all_scopes(outlog);
    outlog << "################################" << endl << endl;

    outlog << "Total lines : " << lines ;

    outlog.flush(); 
    outlog.close();  
    fclose(yyin);   
    
    delete st;       
    return 0;
}