/* Script for processing the replica exchange log produced by AMBER. It takes three arguments, 
the replica exchange log file, the exchange frequency, and the number of exchanges that took place.
It outputs to the screen a simplified log file showing the replica exchange history.*/
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <cstdlib>

using namespace std;

int main( int argc, char** argv )
{
	//reader for log file
	ifstream reader;
	//exchange frequency and number of exchanges
	int exchange_frequency, steps;
	//temporary variable for holding ph values
	double ph;
	//variables for reading in file
	string line, junk;
	//open log file
	reader.open( argv[1] );
	//store exchange frequency
	exchange_frequency = atoi( argv[2] );
	//store the number of exchanges
	steps = atoi( argv[3] );
	//Discard header
	while( getline( reader, line ) && line.find( "Rep#" ) == string::npos );
        getline( reader, line );
	//Parse log file
	for( int i = 0; i < steps; i++ )
	{
		vector<double> phs;
		while( getline( reader, line ) && line[0] != '#' )
		{
			stringstream line_reader;
			line_reader << line;
			line_reader >> junk;
			line_reader >> junk;
			line_reader >> junk;
			line_reader >> ph;
			phs.push_back( ph );
		}
		//print simplified history file
		cout << i * exchange_frequency;
		for( int i = 0; i < phs.size(); i++ )
			cout << ' ' << phs[i];
		cout << '\n';
	}
	return 0;
}
