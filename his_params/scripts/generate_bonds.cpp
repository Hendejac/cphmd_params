#include <iostream>
#include <fstream>
#include <string>
#include <cstdlib>
#include <vector>

using namespace std;

int main( int argc, char** argv )
{
	ifstream pdb_file;
	int atomic_number;
	string line, parm;
	vector<int> he1s, he2s;
	vector<double> rs;
	pdb_file.open( argv[1] );
	parm = argv[2];
	while( getline( pdb_file, line ) )
	{
		if( ( line.find( "HE1" ) != string::npos && line.find( "GL2" ) != string::npos ) || ( line.find( "HD1" ) != string::npos && line.find( "AS2" ) != string::npos ) )
		{
			he1s.push_back( atoi( line.substr( 4, 7 ).c_str() ) );
			if( line.find( "GL2" ) != string::npos )
				rs.push_back( 2.05 );
			else
				rs.push_back( 2.16 );
		} 
		if( ( line.find( "HE2" ) != string::npos && line.find( "GL2" ) != string::npos ) || ( line.find( "HD2" ) != string::npos && line.find( "AS2" ) != string::npos ) )
			he2s.push_back( atoi( line.substr( 4, 7 ).c_str() ) );
	}
	cout << "parm " << parm << ".parm7\n";
	for( int i = 0; i < he1s.size(); i++ )
		cout << "setBond @" << he1s[i] << " @" << he2s[i] << " 0.0 " << rs[i] << "\n";
	cout << "outparm " << parm << "_exclusions.parm7\n";
	cout << "quit\n";
	return 0;
}
