/*This file takes 6 arguments and prints out "wrapped" lambda files
The arguments follow:
1. The simplified replica exchange file produced by walker_extraction.cpp
2. A file containing the ph values of the lambda files in order with 1 ph on a line
3. A list of the unwrapped lambda files produced by AMBER in ph order one file name on a line.
4. The number of steps in the simulation (500000/ns, typically)
5. The number of steps between replica exchanges
6. The number of steps between prints to the screen

This file assumes that the lambda files have proper header information.*/
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <vector>
#include <string>
#include <sstream>

using namespace std;

int main( int argc, char** argv )
{
	ifstream repwalk_reader, ph_list_reader, file_list_reader, file_reader;
	ofstream writer;
	int index, steps, steps_between_exchanges, steps_between_prints;
	double ph;
	string line, junk, file_name, ph_string;
	vector<string> phs;
	vector<vector<int> > indices;
	vector<vector<string> > lambda_lines;
	repwalk_reader.open( argv[1] );
	ph_list_reader.open( argv[2] );
	file_list_reader.open( argv[3] );
	steps = atoi( argv[4] );
	steps_between_exchanges = atoi( argv[5] );
	steps_between_prints = atoi( argv[6] );
	//read in phs
	while( ph_list_reader >> ph_string )
		phs.push_back( ph_string );
	//read in simplified replica exchange log
	for( int i = 0; i < steps / steps_between_exchanges; i++ )
	{
		stringstream line_reader;
		vector<int> temp_indices;
		getline( repwalk_reader, line );
		line_reader << line;
		line_reader >> junk;
		for( int j = 0; j < phs.size(); j++ )
		{
			line_reader >> ph;
			for( int k = 0; k < phs.size(); k++ )
				if( ph == atof( phs[k].c_str() ) )
				{
					temp_indices.push_back( k );
					break;
				}
		}
		indices.push_back( temp_indices );
	}
	//Read in unwrapped lambda files
	while( file_list_reader >> file_name )
	{
		vector<string> temp_lambda_lines;
		file_reader.open( file_name.c_str() );
		while( getline( file_reader, line ) && line[0] == '#' )
			temp_lambda_lines.push_back( line );
		for( int i = 0; i < steps / steps_between_prints; i++ )
		{
			temp_lambda_lines.push_back( line );
			getline( file_reader, line );
		}
		lambda_lines.push_back( temp_lambda_lines );
		file_reader.close();
	}
	//Sort lambda files and print out wrapped lambda files
	for( int i = 0; i < phs.size(); i++ )
	{
		stringstream local_file_name;
		local_file_name << "out.ph" << phs[i] << ".lambda";
		writer.open( ( local_file_name.str() ).c_str() );
		for( int j = 0; j < 4; j++ )
			writer << lambda_lines[i][j] << '\n';
		for( int j = 0; j < steps / steps_between_prints; j++ )
		{
			for( int k = 0; k < phs.size(); k++ )
				if( indices[j * steps_between_prints / steps_between_exchanges][k] == i )
				{
					index = k;
					break;
				}
			writer << lambda_lines[index][j+4] << '\n';
		}
		writer.close();
	}
	return 0;
}
