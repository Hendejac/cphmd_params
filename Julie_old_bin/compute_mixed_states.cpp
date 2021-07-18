#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <vector>
#include <cstdlib>

using namespace std;

int main( int argc, char** argv )
{
	ifstream lambda_file;
	stringstream line_reader;
	bool good, first = true;
	int ires, oldres, count = 0;
	double biglamb, smalllamb, lambda;
	string line, junk;
	vector<int> residues;
	vector<int> total_counts;
	vector<vector<int> > counts;
	lambda_file.open( argv[1] );
	smalllamb = atof( argv[2] );
	biglamb = 1.0 - smalllamb;
	getline( lambda_file, line );
	getline( lambda_file, line );
	line_reader << line;
	line_reader >> junk;
	line_reader >> junk;
	while( line_reader >> ires )
	{
		if( first )
		{
			vector<int> temp_counts;
			temp_counts.push_back( 0 );
			first = false;
			counts.push_back( temp_counts );
			oldres = ires;
			residues.push_back( ires );
			total_counts.push_back( 0 );
		}
		else if( ires == oldres )
			counts[counts.size()-1].push_back( 0 );
		else
		{
			vector<int> temp_counts;
			temp_counts.push_back( 0 );
			oldres = ires;
			residues.push_back( ires );
			counts.push_back( temp_counts );
			total_counts.push_back( 0 );
		}
	}
	getline( lambda_file, line );
	getline( lambda_file, line );
	while( getline( lambda_file, line ) )
	{
		stringstream line_reader2;
		line_reader2 << line;
		line_reader2 >> junk;
		for( int i = 0; i < counts.size(); i++ )
		{
			good = true;
			for( int j = 0; j < counts[i].size(); j++ )
			{
				line_reader2 >> lambda;
				if( lambda < biglamb && lambda > smalllamb )
				{
					counts[i][j]++;
					good = false;
				}
			}
			if( !good )
				total_counts[i]++;
		}
		count++;
	}
	for( int i = 0; i < counts.size(); i++ )
	{
		cout << "Residue " << residues[i] << ' ' << 1.0 * counts[i][0] / count << " mixed lambda states";
		if( counts[i].size() > 1 )
			cout << " and " << 1.0 * counts[i][1] / count << " mixed X states and " << 1.0 * total_counts[i] / count << " total mixed states";
		cout << '\n';
	}
	return 0;
}
