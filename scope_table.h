#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope=NULL;
    vector<list<symbol_info *> > table;

    int hash_function(string name)
    {
        int hash=0;
        for(int i=0; i<name.length(); i++)
        {
            hash=(hash*31+name[i])%bucket_count;
        }
        return hash;
    }

public:
    scope_table()
    {
        bucket_count=0;
        unique_id=0;
        parent_scope=NULL;
    }
    
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
    {
        this->bucket_count=bucket_count;
        this->unique_id=unique_id;
        this->parent_scope=parent_scope;
        table.resize(bucket_count);
    }
    
    scope_table *get_parent_scope()
    {
        return parent_scope;
    }
    
    int get_unique_id()
    {
        return unique_id;
    }
    
    symbol_info *lookup_in_scope(symbol_info* symbol)
    {
        int hash_val=hash_function(symbol->getname());
        for(list<symbol_info*>::iterator it=table[hash_val].begin(); it!=table[hash_val].end(); it++)
        {
            if((*it)->getname()==symbol->getname())
            {
                return *it;
            }
        }
        return NULL;
    }
    
    bool insert_in_scope(symbol_info* symbol)
    {
        if(lookup_in_scope(symbol)!=NULL)
        {
            return false; // already exists
        }
        
        int hash_val=hash_function(symbol->getname());
        symbol->set_scope_id(unique_id);
        table[hash_val].push_back(symbol);
        return true;
    }
    
    bool delete_from_scope(symbol_info* symbol)
    {
        int hash_val=hash_function(symbol->getname());
        for(list<symbol_info*>::iterator it=table[hash_val].begin(); it!=table[hash_val].end(); it++)
        {
            if((*it)->getname()==symbol->getname())
            {
                table[hash_val].erase(it);
                return true;
            }
        }
        return false;
    }
    
    void print_scope_table(ofstream& outlog)
    {
        outlog<<"ScopeTable # "<<unique_id<<endl;
        
        for(int i=0; i<bucket_count; i++)
        {
            if(!table[i].empty())
            {
                outlog<<" "<<i<<" --> " << endl;
                for(list<symbol_info*>::iterator it=table[i].begin(); it!=table[i].end(); it++)
                {
                    if(it!=table[i].begin()) outlog<<" ";
                    outlog<<"< "<<(*it)->getname()<<" : "<<(*it)->gettype()<<" >"<<endl;
                    
                    if((*it)->get_symbol_type()=="variable")
                    {
                        outlog<<"Variable"<<endl;
                        outlog<<"Type: "<<(*it)->get_data_type()<<endl<<endl;
                    }
                    else if((*it)->get_symbol_type()=="array")
                    {
                        outlog<<"Array"<<endl;
                        outlog<<"Type: "<<(*it)->get_data_type()<<endl;
                        outlog<<"Size: "<<(*it)->get_array_size()<<endl<<endl;
                    }
                    else if((*it)->get_symbol_type()=="function")
                    {
                        outlog<<"Function Definition"<<endl;
                        outlog<<"Return Type: "<<(*it)->get_data_type()<<endl;
                        outlog<<"Number of Parameters: "<<(*it)->get_parameters().size()<<endl;
                        outlog<<"Parameter Details: "<<(*it)->get_parameters_string()<<endl<<endl;
                    }
                }
            }
        }
    }
    
    ~scope_table()
    {
        for(int i=0; i<bucket_count; i++)
        {
            for(list<symbol_info*>::iterator it=table[i].begin(); it!=table[i].end(); it++)
            {
                delete *it;
            }
        }
    }
}; 