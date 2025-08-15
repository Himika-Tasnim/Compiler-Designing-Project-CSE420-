#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include "scope_table.h"

extern ofstream outlog;

class symbol_table {
private:
    int bucket_count;
    int current_scope_id;

public:
    scope_table* current_scope;

public:
    symbol_table(int bucket_count) {
        this->bucket_count = bucket_count;
        this->current_scope_id = 1;
        this->current_scope = new scope_table(bucket_count, current_scope_id, NULL); // auto enter global scope
        outlog << "New ScopeTable with ID " << current_scope_id << " created" << endl << endl;
        current_scope_id++;
    }

    ~symbol_table() {
        while (current_scope != NULL) {
            scope_table* temp = current_scope;
            current_scope = current_scope->get_parent_scope();
            delete temp;
        }
    }

    void enter_scope() {
        scope_table* new_scope = new scope_table(bucket_count, current_scope_id, current_scope);
        current_scope = new_scope;
        outlog << "New ScopeTable with ID " << current_scope_id << " created" << endl << endl;
        current_scope_id++;
    }

    void exit_scope() {
        if (current_scope != NULL) {
            outlog << "Scopetable with ID " << current_scope->get_unique_id() << " removed" << endl;
            scope_table* temp = current_scope;
            current_scope = current_scope->get_parent_scope();
            delete temp;
        }
    }

    bool insert(symbol_info* symbol) {
        if (current_scope == NULL) return false;
        return current_scope->insert_in_scope(symbol);
    }

    symbol_info* lookup(symbol_info* symbol) {
        scope_table* temp = current_scope;
        while (temp != NULL) {
            symbol_info* found = temp->lookup_in_scope(symbol);
            if (found != NULL) return found;
            temp = temp->get_parent_scope();
        }
        return NULL;
    }

    void print_current_scope(ofstream& outlog) {
        if (current_scope != NULL)
            current_scope->print_scope_table(outlog);
    }

    void print_all_scopes(ofstream& outlog) {
        scope_table* temp = current_scope;
        while (temp != NULL) {
            temp->print_scope_table(outlog);
            temp = temp->get_parent_scope();
        }
    }
};

#endif
