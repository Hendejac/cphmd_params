#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <cstdlib>
#include <vector>

using namespace std;

#define BIGLAMBDA 0.8
#define SMALLLAMBDA 0.2

int main( int argc, char** argv )
{
	ifstream reader, file_list_reader;
	bool found;
	int index, counter, resid, desired_resid, steps_between_prints;
	double value;
	string line, junk, file_name;
	vector<vector<double> > running_s;
	file_list_reader.open( argv[1] );
	desired_resid = atoi( argv[2] );
	steps_between_prints = atoi( argv[3] );
	while( file_list_reader >> file_name )
	{
		int big_lambda_count = 0, small_lambda_count = 0;
		stringstream line_reader;
		vector<double> temp_running_s;
		reader.open( file_name.c_str() );
		getline( reader, line );
		getline( reader, line );
		line_reader << line;
		line_reader >> junk;
		line_reader >> junk;
		counter = 0;
		found = false;
		while( line_reader >> resid )
		{
			if( resid == desired_resid )
			{
				found = true;
				index = counter;
				break;
			}
			counter++;
		}
		if( !found )
		{
			cout << "I did not find the residue.\n";
			return 0;
		}
		getline( reader, line );
		getline( reader, line );
		while( getline( reader, line ) )
		{
			stringstream line_reader2;
			line_reader2 << line;
			for( int i = 0; i <= index; i++ )
				line_reader2 >> junk;
			line_reader2 >> value;
			if( value > BIGLAMBDA )
				big_lambda_count++;
			if( value < SMALLLAMBDA )
				small_lambda_count++;
			temp_running_s.push_back( 1.0 * big_lambda_count / ( big_lambda_count + small_lambda_count ) );
		}
		running_s.push_back( temp_running_s );
		reader.close();
	}
	for( int i = 0; i < running_s[0].size(); i++ )
	{
		cout << ( i + 1 ) * steps_between_prints;
		for( int j = 0; j < running_s.size(); j++ )
		{
			cout << ' ' << running_s[j][i];
		}
		cout << '\n';
	}
	return 0;
}
