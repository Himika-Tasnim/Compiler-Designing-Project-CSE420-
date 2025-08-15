#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include <bits/stdc++.h>
using namespace std;

class symbol_info {
private:
    string name;
    string type;
    string symbol_type;  // "variable", "array", "function"
    string data_type;    // "int", "float", "void"
    vector<string> parameters; // only for function parameters
    int array_size = 0;        // only for arrays
    int scope_id = 0;          // scope where this symbol is declared

public:
    symbol_info(string name, string type)
        : name(name), type(type) {}

    symbol_info(string name, string type, string symbol_type, string data_type)
        : name(name), type(type), symbol_type(symbol_type), data_type(data_type) {}

    // Getters
    string getname() const { return name; }
    string gettype() const { return type; }
    string get_symbol_type() const { return symbol_type; }
    string get_data_type() const { return data_type; }
    vector<string> get_parameters() const { return parameters; }
    int get_array_size() const { return array_size; }
    int get_scope_id() const { return scope_id; }

    // Setters
    void setname(const string& n) { name = n; }
    void settype(const string& t) { type = t; }
    void set_symbol_type(const string& st) { symbol_type = st; }
    void set_data_type(const string& dt) { data_type = dt; }
    void set_parameters(const vector<string>& params) { parameters = params; }
    void set_array_size(int size) { array_size = size; }
    void set_scope_id(int id) { scope_id = id; }

    void add_parameter(const string& param) {
        parameters.push_back(param);
    }

    string get_parameters_string() const {
        string result;
        for (size_t i = 0; i < parameters.size(); ++i) {
            if (i > 0) result += ", ";
            result += parameters[i];
        }
        return result;
    }

    ~symbol_info() = default; 
};

#endif
