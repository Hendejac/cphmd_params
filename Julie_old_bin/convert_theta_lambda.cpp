#include <iostream>
#include <fstream>
#include <iomanip>
#include <cmath>
#include <string>
#include <sstream>

using namespace std;

int main( int argc, char** argv )
{
	ifstream reader;
	int step;
	double theta, dudtheta;
	string line;
	reader.open( argv[1] );
	while( getline( reader, line ) )
	{
		stringstream line_reader;
		line_reader << line;
		line_reader >> step;
		cout << setw( 8 ) << right << step;
		while( line_reader >> theta )
		{
			line_reader >> dudtheta;
			cout << setw( 10 ) << right << fixed << setprecision( 4 ) << sin( theta ) * sin( theta ); 
		}
		cout << '\n';
	}
	return 0;
}
