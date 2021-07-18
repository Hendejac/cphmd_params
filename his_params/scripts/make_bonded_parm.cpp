#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <iomanip>

using namespace std;

int main( int argc, char** argv )
{
	ifstream pdb_reader, parm_reader;
	int k_index, r_index, index, pointer, atom_counter = 0;
	double k, r;
	string line;
	vector<int> hd1s, hd2s, indices, pointers;
	vector<double> ks, rs;
	pdb_reader.open( argv[1] );
	parm_reader.open( argv[2] );
	while( getline( pdb_reader, line ) )
		if( line.find( "ATOM" ) != string::npos ) 
		{
			atom_counter++;
			if( line.find( "AS2" ) != string::npos && line.find( "HD1" ) != string::npos )
				hd1s.push_back( atom_counter );
			if( line.find( "AS2" ) != string::npos && line.find( "HD2" ) != string::npos )
				hd2s.push_back( atom_counter );
			if( line.find( "GL2" ) != string::npos && line.find( "HE1" ) != string::npos )
				hd1s.push_back( atom_counter );
			if( line.find( "GL2" ) != string::npos && line.find( "HE2" ) != string::npos )
				hd2s.push_back( atom_counter );
		}
	while( getline( parm_reader, line ) && line.find( "FLAG POINTERS" ) == string::npos )
		cout << line << '\n';
	cout << line << '\n';
	getline( parm_reader, line );
	cout << line << '\n';
	while( getline( parm_reader, line ) && line.find( "FLAG" ) == string::npos )
	{
		stringstream line_reader;
		line_reader << line;
		while( line_reader >> pointer )
			pointers.push_back( pointer );
	}
	pointers[3] += hd1s.size();
	pointers[12] += hd1s.size();
        pointers[15]++;
	for( int i = 0; i < pointers.size(); i++ )
	{
		cout << setw( 8 ) << right << pointers[i];
                if( i % 10 == 9 || i == pointers.size() - 1 )
			cout << '\n';
	} 
	cout << line << '\n';
	getline( parm_reader, line );
	cout << line << '\n';
	while( getline( parm_reader, line ) && line.find( "BOND_FORCE_CONSTANT" ) == string::npos )
		cout << line << '\n';
	cout << line << '\n';
	getline( parm_reader, line );
	cout << line << '\n';
	while( getline( parm_reader, line ) && line.find( "FLAG" ) == string::npos )
	{
		stringstream line_reader;
		line_reader << line;
		while( line_reader >> k )
			ks.push_back( k );
	}
	ks.push_back( 0 );
	k_index = ks.size();
	for( int i = 0; i < ks.size(); i++ )
	{
		cout << setw( 16 ) << right << scientific << setprecision( 8 ) << uppercase << ks[i] << nouppercase;
		if( i % 5 == 4 || i == ks.size() - 1 )
			cout << '\n'; 
	}
	cout << line << '\n';
	getline( parm_reader, line );
	cout << line << '\n';
	while( getline( parm_reader, line ) && line.find( "FLAG" ) == string::npos )
	{
		stringstream line_reader;
		line_reader << line;
		while( line_reader >> r )
			rs.push_back( r );
	}
	rs.push_back( 2.1 );
	r_index = rs.size();
	for( int i = 0; i < rs.size(); i++ )
	{
		cout << setw( 16 ) << right << scientific << setprecision( 8 ) << uppercase << rs[i] << nouppercase;
		if( i % 5 == 4 || i == rs.size() - 1 )
			cout << '\n'; 
	}
	cout << line << '\n';
	while( getline( parm_reader, line ) && line.find( "BONDS_WITHOUT_HYDROGEN" ) == string::npos )
		cout << line << '\n';
	cout << line << '\n';
	getline( parm_reader, line );
	cout << line << '\n';
	while( getline( parm_reader, line ) && line.find( "FLAG" ) == string::npos )
	{
		stringstream line_reader;
		line_reader << line;
		while( line_reader >> index )
			indices.push_back( index );
	}
	for( int i = 0; i < hd1s.size(); i++ )
	{
		indices.push_back( ( hd1s[i] - 1 ) * 3 );
		indices.push_back( ( hd2s[i] - 1 ) * 3 );
		indices.push_back( k_index );
	}
	for( int i = 0; i < indices.size(); i++ )
	{
		cout << setw( 8 ) << right << indices[i];
		if( i % 10 == 9 || i == indices.size() - 1 )
			cout << '\n'; 
	}
	cout << line << '\n';
	while( getline( parm_reader, line ) )
		cout << line << '\n';
	return 0;
}
