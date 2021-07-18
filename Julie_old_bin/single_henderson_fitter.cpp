//g++ -o single_henderson_fitter single_henderson_fitter.cpp -lgsl -lgslcblas
#include <iostream>
#include <fstream>
#include <vector>
#include <cmath>
#include <gsl/gsl_fit.h>

using namespace std;

#define DELTA 1e-5

int main( int argc, char** argv )
{
	ifstream reader;
	int num_xs = 0, counter = 0;
	double ph, s, npka, n, cov00, cov01, cov11, sumsq, *x = NULL, *y = NULL;
	vector<double> phs, ss;
	reader.open( argv[1] );
	while( reader >> ph )
	{
		phs.push_back( ph );
		reader >> s;
		ss.push_back( s );
	}
	for( int i = 0; i < ss.size(); i++ )
		if( ss[i] > DELTA && 1.0 - ss[i] > DELTA )
			num_xs++;
	x = new double[num_xs];
	y = new double[num_xs];
	for( int i = 0; i < ss.size(); i++ )
		if( ss[i] > DELTA && 1.0 - ss[i] > DELTA )
		{
			x[counter] = phs[i];
			y[counter] = log10( ( 1.0 - ss[i] ) / ss[i] );
			counter++;
		}
	gsl_fit_linear( x, 1, y, 1, num_xs, &npka, &n, &cov00, &cov01, &cov11, &sumsq );
	cout << "#pKa: " << -1.0 * npka / n << '\n';
	cout << "#n: " << -n << '\n';
	for( int i = 0; i < phs.size(); i++ )
		cout << phs[i] << ' ' << 1.0 / ( 1.0 + pow( 10, ( n * phs[i] + npka ) ) ) << '\n';;
	delete x;
	delete y;
	return 0;
}
