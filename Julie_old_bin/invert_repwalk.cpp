#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <sstream>

using namespace std;

int main( int argc, char** argv )
{
	ifstream ph_list, repwalk_file;
	int counter, step;
	double ph, value;
	string line;
	vector<double> phs;
	ph_list.open( argv[1] );
	repwalk_file.open( argv[2] );
	while( ph_list >> ph )
		phs.push_back( ph );
	while( getline( repwalk_file, line ) )
	{
		stringstream line_reader2;
		line_reader2 >> step;
		cout << step;
		for( int i = 0; i < phs.size(); i++ )
		{
			stringstream line_reader;
			line_reader << line;
			line_reader >> step;
			counter = 0;
			while( line_reader >> value )
			{
				if( value == phs[i] )
				{
					cout << ' ' << counter;
					break;
				}
				counter++;
			}
		}
		cout << '\n';
	}
	return 0;
}
