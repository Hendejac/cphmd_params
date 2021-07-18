#!/usr/bin/perl

# Compute fractional of time in unprotonation state S_i^{unprot}
# = N_i^u/N_i^u + N_i^p
# tautomer information contained in the file
# 0 for single titration site; 2 for HSP, 4 for ASP/GLU
# Usage: CptSX.pl [file] [start] [end] [pH]

sub usage {
   printf STDERR "Usage: CptSX.pl [file] [start] [end] [pH]\n";
   exit 1;
}
		    

if(!$ARGV[0]){
   &usage()
}

while ($#ARGV>=0) {
    if ($ARGV[0] eq "-help" || $ARGV[0] eq "-h") {
    &usage();
    }
    $file = shift @ARGV;
    $start = shift @ARGV;
    $end = shift @ARGV;
    $pH = shift @ARGV;
    }

open (INFILE,"$file");
open (OUTFILE,">$file-$start-$end.sx");

$lam_p = 0.2;
$lam_up = 1-$lam_p;
$ititr = 0;
$iline = 0;
$Nframe =0;

while (<INFILE>) {
  @lambda = split(" ",$_);
  if ($lambda[0] =~ /#/) {
    if ($lambda[1] =~ /ires/) {
      shift @lambda;
      @ires = @lambda;
    }
    if ($lambda[1] =~ /itauto/) {
      shift @lambda;
      @iTauto = @lambda;
      $Ntitr = @iTauto -1; # $iTauto[0]=itaut
      #Extend indexes
      $ititr = 0;
      for ($i=1; $i <= $Ntitr; $i++) {
        $ititr ++;
        $ires2[$ititr] = $ires[$i];
        $iTauto2[$ititr] = $iTauto[$i];
        if($iTauto[$i] == 2 || $iTauto[$i] == 4) {
          $ititr ++;
          $ires2[$ititr] = $ires[$i];
          $iTauto2[$ititr] = $iTauto[$i];
        }
      }
      $Ntitr2 = $ititr;
      for ($i=1; $i <= $Ntitr2; $i++) {
	$Nunprot[$i] = 0; $Nprot[$i] = 0; $Nmix[$i] = 0;
      }
    }
  }
  else {
    $iline ++;
    if ($iline <= $end && $iline >=$start) {
      $Nframe ++;
      $ititr = 0;
      if ($lambda[0] !~ /\./) {
        shift @lambda;
      }
      foreach $lam(@lambda) {
	$ititr ++;
	$LamVal[$ititr] = $lam;
	# pure
	if ($lam >= $lam_up) {$Nunprot[$ititr] ++;}
	if ($lam <= $lam_p) {$Nprot[$ititr] ++;}
	# mixed
	if ($lam < $lam_up && $lam > $lam_p) {
	  $Nmix[$ititr] ++;
          # hsp: unprotonated state needs to be pure tautomer
          if ($iTauto2[$ititr] == 2 && $LamVal[$ititr-1] >= $lam_up) {
            $Nunprot[$ititr-1] = $Nunprot[$ititr-1]-1;
            $Nmix[$ititr-1] ++;
          }
          if ($iTauto2[$ititr] == 2 && $LamVal[$ititr-1] <= $lam_p ){
            $Nprot[$ititr-1] = $Nprot[$ititr-1]-1;
            $Nmix[$ititr-1] ++;
          }
          # asp/glu: protonated state needs to be pure tautomer
          if ($iTauto2[$ititr] == 4 && $LamVal[$ititr-1] <= $lam_p ){
            $Nprot[$ititr-1] = $Nprot[$ititr-1]-1;
            $Nmix[$ititr-1] ++;
          }
          if ($iTauto2[$ititr] == 4 && $LamVal[$ititr-1] >= $lam_up) {
            $Nunprot[$ititr-1] = $Nunprot[$ititr-1]-1;
            $Nmix[$ititr-1] ++;
          }
	} # mixed
        #substract what has been added as above
        if ($iTauto2[$ititr] == 2 || $iTauto2[$ititr] == 4) {
          if ($lam >= $lam_up) {$Nunprot[$ititr] --;}
          if ($lam <= $lam_p) {$Nprot[$ititr] --;}
        }#substract
        #count for each site of double-site titration
        if ($iTauto2[$ititr] == 2 || $iTauto2[$ititr] == 4) {
          if ($lam >= $lam_up ) {$jtitr=$ititr;}
          if ($lam <= $lam_p  ) {$jtitr=$ititr+1;}
          if ($lam >= $lam_up || $lam <= $lam_p) {
            if ($LamVal[$ititr-1] >= $lam_up) {$Nunprot[$jtitr] ++;}
            if ($LamVal[$ititr-1] <= $lam_p) {$Nprot[$jtitr] ++;}
            if ($LamVal[$ititr-1] < $lam_up && $LamVal[$ititr-1] > $lam_p) {$Nmix[$jtitr] ++;}
          }
          $ititr ++;
        }#count
      } # each lambda
    } # if within start and end
  } # lambda lines
} # while

printf "pH %4d frames %8d totres %4d\n", $pH, $Nframe, $Ntitr;
printf OUTFILE "  # %5s %6s %4s %8s %4s %6s\n",
"ires", "itaut", "pH", "S(unprot)", "pure", "mixed",;

# compute fraction of time in unprot states
for ($i=1; $i <= $Ntitr2; $i++) {
  print "grp $i Nunprot $Nunprot[$i] Nprot $Nprot[$i] mixed $Nmix[$i]\n";
  $S[$i] = $Nunprot[$i] + $Nprot[$i];
  $PurePercent[$i] = $S[$i]/$Nframe;
  $MixPercent[$i] = $Nmix[$i]/$Nframe;
  #tautomers
  if ($iTauto2[$i] == 2 && $iTauto2[$i-1] == 1) {
        $S[$i] = $Nunprot[$i] + $Nprot[$i-1];
  }
  if ($iTauto2[$i] == 2 && $iTauto2[$i-1] == 2) {
        $S[$i] = $Nunprot[$i] + $Nprot[$i-2];
  }
  if ($iTauto2[$i] == 4 && $iTauto2[$i-1] == 3) {
        $S[$i] = $Nunprot[$i-1] + $Nprot[$i];
        $Nunprot[$i] = $Nunprot[$i-1];
  }
  if ($iTauto2[$i] == 4 && $iTauto2[$i-1] == 4) {
        $S[$i] = $Nunprot[$i-2] + $Nprot[$i];
        $Nunprot[$i] = $Nunprot[$i-2];
  }
  if ($S[$i] > 0) {
	$S[$i] = $Nunprot[$i]/$S[$i];
	print "s= $S[$i]\n";
  }
  else {
    $S[$i] = -1;
  }
  printf OUTFILE "%3d %5d %5d %6.1f %6.2f %6.2f %6.2f\n",
    $i, $ires2[$i], $iTauto2[$i], $pH, $S[$i], $PurePercent[$i], $MixPercent[$i];
}
