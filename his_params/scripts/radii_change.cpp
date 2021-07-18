#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <iomanip>

using namespace std;

int main( int argc, char** argv )
{
	ifstream pdb, parm;
	int counter = 0;
	double radius;
	string line;
	vector<int> indices;
	vector<double> radii;
	pdb.open( argv[1] );
	parm.open( argv[2] );
	while( getline( pdb, line ) )
		if( line.find( "ATOM" ) != string::npos )
		{
			if( line.find( "HIP" ) != string::npos && ( line.find( "ND1" ) != string::npos || line.find( "NE2" ) != string::npos ) )
				indices.push_back( counter );
			counter++;
		}
	while( getline( parm, line ) && line.find( "RADII" ) == string::npos )
		cout << line << '\n';
	cout << line << '\n';
	getline( parm, line );
	cout << line << '\n';
	while( getline( parm, line ) && line.find( "FLAG" ) == string::npos )
	{
		stringstream line_reader;
		line_reader << line;
		while( line_reader >> radius )
			radii.push_back( radius );
	}
	for( int i = 0; i < indices.size(); i++ )
	{
		radii[indices[i]+1] = 1.17;
	}
	for( int i = 0; i < radii.size(); i++ )
	{
		cout << setw( 16 ) << right << scientific << setprecision( 8 ) << uppercase << radii[i] << nouppercase;
		if( i % 5 == 4 || i == radii.size() - 1 )
			cout << '\n'; 
	}
	cout << line << '\n';
	while( getline( parm, line ) )
		cout << line << '\n';
	return 0;
}
