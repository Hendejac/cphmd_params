#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <cstdlib>
#include <cstring>

using namespace std;

int main( int argc, char** argv )
{
	ifstream reader;
	bool first = true;
	int residue, old_residue, new_residue;
	string line;
	reader.open( argv[1] );
	while( getline( reader, line ) )
		if( line.find( "ATOM" ) != string::npos )
		{
			residue = atoi( line.substr( 22, 4 ).c_str() );
			if( first )
			{
				first = false; 
				new_residue = 1;
				old_residue = residue;
			}
			if( residue != old_residue )
			{
				old_residue = residue;
				new_residue++;
			}
			for( int i = 0; i < 22; i++ )
				cout << line[i];
			cout << setw( 4 ) << right << new_residue;
			for( int i = 26; i < strlen( line.c_str() ); i++ )
				cout << line[i];
			cout << '\n';
		}	
		else
			cout << line << '\n';
	return 0;
}
