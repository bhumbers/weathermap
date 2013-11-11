function [ output_args ] = downloadDataForDay( year, dayNum )
%GETDATAFORDAY Summary of this function goes here
%   Detailed explanation goes here

rootURL = 'ftp://hydro1.sci.gsfc.nasa.gov/data/s4pa/NLDAS/NLDAS_FORA0125_H.002';
yearDir = num2str(year);
dayDir = sprintf('%03d',dayNum);

%Grabs all GRB files in specified directory
cmd = ['wget -r --no-parent --accept "*.grb"  ' rootURL '/' yearDir '/' dayDir '/']
system(cmd, '-echo');

end
